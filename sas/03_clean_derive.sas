/*********************************************************************
*  PROGRAM : 03_clean_derive.sas
*  PURPOSE : Derive monthly performance fields and loan-level
*            performance flags from the raw monthly records.
*  INPUT   : FMLIB.LP_RAW
*  OUTPUT  : FMLIB.LP_PERF   - one row per loan per month, with
*                              carried-forward delinquency status
*            FMLIB.LOAN_PERF - one row per loan (last record),
*                              ever-90 and default flags
*  RUN     : After 02_import_raw.sas.
*
*  NOTE    : Representative legacy program written for the
*            SAS-to-Databricks migration project.
*********************************************************************/

/* MIGRATION NOTE - sort key and missing values.
   Sort on the derived SAS date rpt_dt, never on the raw MMYYYY
   string: as text, "012008" sorts before "022007".
   A missing rpt_dt (blank/malformed period) sorts FIRST within the
   loan, because SAS missing values sort below every number. Spark
   ORDER BY ... ASC also defaults to NULLS FIRST, so the result
   matches today - but write NULLS FIRST explicitly in the window
   spec so the equivalence is deliberate, not accidental.            */
proc sort data=fmlib.lp_raw out=work.lp_sorted;
   by loan_identifier rpt_dt;
run;

data fmlib.lp_perf  (drop=_last_known_dlq last_rpt_dt last_zb_code
                          last_zb_dt default_flag)
     fmlib.loan_perf(keep=loan_identifier first_rpt_dt last_rpt_dt
                          months_observed ever_d90 first_d90_dt max_dlq
                          last_zb_code last_zb_dt default_flag);
   set work.lp_sorted;
   by loan_identifier rpt_dt;

   length perf_status $10 last_zb_code $3;
   format first_rpt_dt last_rpt_dt first_d90_dt last_zb_dt monyy7.;

   /* MIGRATION NOTE - RETAIN with BY-group state.
      A DATA step processes one row at a time. Normally every variable
      not read by SET is reset to missing at the top of each row;
      RETAIN keeps its value from the previous row instead. Combined
      with BY-group processing, FIRST.loan_identifier is 1 on a loan's
      first row and LAST.loan_identifier is 1 on its last row, so the
      retained variables act as per-loan running state:
        _last_known_dlq  last numeric delinquency status seen
        first_rpt_dt     first reporting period of the loan
        ever_d90         1 once the loan has ever reached 90+ days
        first_d90_dt     reporting period of that first 90+ month
        max_dlq          worst status so far
      The reset block under FIRST. is what stops state leaking from one
      loan into the next. Row order inside the loan comes from the
      PROC SORT above - the DATA step has no ORDER BY of its own.
      PySpark has no row-by-row state: translate each retained value
      to a window function over (PARTITION BY loan_identifier ORDER BY
      rpt_dt): last(..., ignorenulls=True) for the carry-forward,
      running max for max_dlq/ever_d90, min(rpt_dt) FILTER for
      first_d90_dt.                                                   */
   retain _last_known_dlq first_rpt_dt ever_d90 first_d90_dt max_dlq;

   if first.loan_identifier then do;
      _last_known_dlq = .;
      first_rpt_dt    = rpt_dt;
      ever_d90        = 0;
      first_d90_dt    = .;
      max_dlq         = .;
      months_observed = 0;
   end;

   /* Sum statement: months_observed is implicitly retained and
      starts at 0. It is reset above at the start of each loan.      */
   months_observed + 1;

   /* Status is "00"-"99" or "XX" (unknown). ?? suppresses the invalid
      data NOTE, so "XX" and blanks become a numeric missing quietly. */
   dlq_num = input(current_loan_delinquency_status, ?? 3.);

   /* Carry the last known status forward over unknown months.       */
   if dlq_num = . then dlq_filled = _last_known_dlq;
   else do;
      dlq_filled      = dlq_num;
      _last_known_dlq = dlq_num;
   end;

   /* MAX() ignores missing arguments (as Spark's greatest() does).   */
   max_dlq = max(max_dlq, dlq_filled);

   /* First-ever 90+ day delinquency. Once set, it never resets
      within the loan, even if the loan cures.                        */
   if dlq_filled >= &d90_threshold and ever_d90 = 0 then do;
      ever_d90     = 1;
      first_d90_dt = rpt_dt;
   end;

   /* MIGRATION NOTE - missing-value ordering in comparisons.
      In SAS a numeric missing (.) is LESS THAN every number, so
      ". < 3" is TRUE. A loan whose first months are "XX" has no known
      status yet, dlq_filled is missing, and it falls into EARLY_DQ.
      In Spark, NULL < 3 is NULL (not true), so the same CASE WHEN
      falls through to the ELSE branch and labels it SERIOUS_DQ.
      To reproduce SAS, the Spark code must test for NULL explicitly
      and send it to EARLY_DQ; better still, quarantine or label it
      UNKNOWN and document the difference in the reconciliation.
      (The >= test for ever_d90 above is safe: ". >= 3" is FALSE in
      SAS and NULL in Spark, and both mean "not flagged".)             */
   if dlq_filled = 0 then perf_status = 'CURRENT';
   else if dlq_filled < &d90_threshold then perf_status = 'EARLY_DQ';
   else perf_status = 'SERIOUS_DQ';

   /* Months on book. INTCK('MONTH') counts month BOUNDARIES crossed,
      not elapsed months: JAN2007 -> FEB2007 is 1. Because the file's
      loan_age counts from the first full month of interest, mob is
      usually loan_age + 1. Kept as-is because downstream reports were
      built on it. Spark equivalent: months_between(rpt, orig) cast to
      int - exact here because both dates are on the 1st.             */
   mob = intck('month', orig_dt, rpt_dt);

   if last.loan_identifier then do;
      last_rpt_dt  = rpt_dt;
      last_zb_code = zero_balance_code;
      last_zb_dt   = zb_dt;

      /* MIGRATION NOTE - character comparison and trailing blanks.
         last_zb_code is $3, so "02" is stored as "02 ". SAS pads the
         shorter operand with blanks before comparing, so IN ('02')
         matches. Spark compares strings exactly - trim() first if the
         value ever arrives padded.                                   */
      default_flag = (ever_d90 = 1 or last_zb_code in (&dflt_zb_codes));

      output fmlib.loan_perf;
   end;

   output fmlib.lp_perf;
run;
