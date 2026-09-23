/*********************************************************************
*  PROGRAM : 05_macro_aggregate.sas
*  PURPOSE : Portfolio summary tables: loan count, average original
*            UPB, average credit score and default rate, by
*            property state, origination quarter and credit score
*            band. Each table is exported to CSV.
*  INPUT   : FMLIB.ABT
*  OUTPUT  : FMLIB.AGG_BY_STATE, FMLIB.AGG_BY_ORIG_QTR,
*            FMLIB.AGG_BY_FICO_BAND and matching CSVs in &out_path
*  RUN     : After 04_build_abt.sas.
*
*  NOTE    : Representative legacy program written for the
*            SAS-to-Databricks migration project.
*********************************************************************/

/* MIGRATION NOTE - FORMAT vs stored value (credit score bands).
   FICOBAND. does not change orig_fico - the stored value is still
   the raw score (e.g. 741). It only changes how the value DISPLAYS,
   and PROC MEANS/FREQ CLASS variables group by the DISPLAYED value.
   So applying this format turns ~400 distinct scores into 5 groups
   without creating any band column. Spark has no equivalent: the
   band must be an explicit CASE WHEN column.
   Range notes:
   - LOW does NOT include missing for a numeric format, so missing
     scores fall to OTHER = '9: Missing'.
   - OTHER also catches anything outside the listed ranges; with
     740-HIGH there is none, but the Spark CASE must still send NULL
     to '9: Missing' explicitly.
   - "-<" excludes the upper bound: 620 is in band 2, not band 1.   */
proc format library=fmlib;
   value ficoband
      low -< 620 = '1: <620'
      620 -< 680 = '2: 620-679'
      680 -< 740 = '3: 680-739'
      740 - high = '4: 740+'
      other      = '9: Missing';
run;

/*-------------------------------------------------------------------
  %AGG_PERF
    groupvar = ABT variable to group by
    grpfmt   = optional format applied to groupvar before grouping
               (include the trailing period, e.g. yyq6.)
    outname  = output dataset name and CSV file name
-------------------------------------------------------------------*/
%macro agg_perf(groupvar=, grpfmt=, outname=);

   %local keyexpr;
   %if &grpfmt ne %then %let keyexpr = left(put(&groupvar, &grpfmt));
   %else %let keyexpr = &groupvar;

   /* MIGRATION NOTE - PROC MEANS and missing CLASS values.
      Without the MISSING option, PROC MEANS DROPS every row whose
      CLASS variable is missing (blank state, missing orig_dt,
      missing score) before computing anything. The PROC SQL step
      below does NOT drop them - GROUP BY keeps a missing group.
      The IF IN_MEANS in the merge then discards the SQL-only group,
      so the published tables exclude those loans entirely, and the
      loan counts across the three tables need not sum to the same
      total. A Spark GROUP BY keeps the NULL group: filter it out
      to reproduce SAS, and record the excluded count.
      For the credit score band this means the '9: Missing' band
      never appears, even though the format defines it.              */
   proc means data=fmlib.abt noprint nway;
      class &groupvar;
      %if &grpfmt ne %then %do;
      format &groupvar &grpfmt;
      %end;
      var original_upb orig_fico;
      output out=work._means (drop=_type_ rename=(_freq_=loan_count))
             mean(original_upb) = avg_orig_upb
             mean(orig_fico)    = avg_credit_score;
   run;

   data work._means;
      set work._means;
      length grp_key $20;
      grp_key = &keyexpr;
   run;

   /* The default rate is computed in SQL, grouped by the FORMATTED
      value via PUT() - PROC SQL groups by the stored value unless
      told otherwise, so without the PUT() origination quarter would
      group by month.                                                 */
   proc sql;
      create table work._dflt as
      select &keyexpr as grp_key length=20,
             sum(default_flag) / count(*) as default_rate
      from fmlib.abt
      group by 1;
   quit;

   proc sort data=work._means; by grp_key; run;
   proc sort data=work._dflt;  by grp_key; run;

   data fmlib.&outname;
      /* RETAIN placed before MERGE only fixes the column order. It
         holds no state: MERGE overwrites every value on every row. */
      retain grp_key loan_count avg_orig_upb avg_credit_score
             default_rate;
      merge work._means (in=in_means)
            work._dflt;
      by grp_key;
      if in_means;

      /* MIGRATION NOTE - FORMAT vs stored value in the exported CSV.
         PROC EXPORT writes FORMATTED values. The stored default_rate
         0.052347... is written as "5.23%", avg_orig_upb 123456.789 as
         "$123,456.79" and avg_credit_score as 741.3. The group
         variable is exported formatted too ("2007Q1", "4: 740+").
         The SAS CSVs are the reconciliation ground truth, so the
         comparison must parse these strings and compare at the
         displayed precision, not against full-precision doubles.   */
      format avg_orig_upb     dollar14.2
             avg_credit_score 5.1
             default_rate     percent8.2;
   run;

   /* Double period: the first ends the macro variable reference,
      the second is the literal dot of ".csv".                       */
   proc export data=fmlib.&outname
        outfile="&out_path/&outname..csv"
        dbms=csv
        replace;
   run;

   proc datasets library=work nolist;
      delete _means _dflt;
   quit;

%mend agg_perf;

/* By property state: character variable, no format.                */
%agg_perf(groupvar=property_state, grpfmt=,          outname=agg_by_state);

/* By origination quarter: orig_dt is stored as the 1st of the
   origination MONTH. YYQ6. displays it as "2007Q1", and PROC MEANS
   groups by that displayed value - so the format alone turns a
   monthly date into a quarterly grouping. Spark must derive the
   quarter explicitly, e.g. concat(year(d), 'Q', quarter(d)).        */
%agg_perf(groupvar=orig_dt,        grpfmt=yyq6.,     outname=agg_by_orig_qtr);

/* By credit score band: see FICOBAND. above.                       */
%agg_perf(groupvar=orig_fico,      grpfmt=ficoband., outname=agg_by_fico_band);
