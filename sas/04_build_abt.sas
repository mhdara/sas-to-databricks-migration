/*********************************************************************
*  PROGRAM : 04_build_abt.sas
*  PURPOSE : Build the analytical base table (ABT): one row per loan,
*            origination attributes joined to derived performance
*            flags.
*  INPUT   : FMLIB.LP_PERF, FMLIB.LOAN_PERF
*  OUTPUT  : FMLIB.ABT
*  RUN     : After 03_clean_derive.sas.
*
*  Origination attributes are taken from the loan's FIRST monthly
*  record (first_rpt_dt), as the file repeats them every month.
*
*  NOTE    : Representative legacy program written for the
*            SAS-to-Databricks migration project.
*********************************************************************/

/* MIGRATION NOTE - indexed correlated subqueries.
   The two correlated subqueries below run once per loan against
   LP_PERF (one row per loan per month). Without an index each run
   is a full table scan - rows x loans - and the job does not finish
   in its batch window. The composite index makes each lookup a
   direct index probe on (loan_identifier, rpt_dt); the COUNT(*)
   subquery uses the leading column alone. MSGLEVEL=I writes
   "INFO: Index LOAN_PERIOD selected" to the log to confirm it.
   03 recreates LP_PERF on every run, which drops the index, so it
   is rebuilt here each time.

   Spark has no indexes. Its optimizer does rewrite correlated
   scalar subqueries into joins by itself, but then the NULL and
   multiple-match behaviour comes from its automatic rewrite
   instead of being chosen. Restructure explicitly: pre-aggregate LP_PERF per
   loan (one row per loan_identifier) and LEFT JOIN it to the outer
   query. That changes the behaviour documented at each subquery,
   so handle every difference deliberately:
   - upb_at_first_d90: SAS matches missing = missing; an equi-join
     on first_d90_dt does not. Decide which you want and test a loan
     with a missing rpt_dt.
   - upb_at_first_d90: SAS ERRORS on more than one match; a join
     silently FANS OUT. Deduplicate the pre-aggregation to one row
     per (loan, month) and assert the ABT grain afterwards.
   - months_30plus: COUNT(*) in a subquery returns 0 when no rows
     match; a LEFT JOIN to a pre-aggregated count returns NULL.
     Wrap it in coalesce(..., 0).                                    */
options msglevel=i;

proc datasets library=fmlib nolist;
   modify lp_perf;
   index create loan_period = (loan_identifier rpt_dt);
quit;

proc sql;
   create table fmlib.abt as
   select a.loan_identifier,
          a.orig_dt,
          a.property_state,
          a.channel,
          a.loan_purpose,
          a.occupancy_status,
          a.original_upb,
          a.original_interest_rate,
          a.original_loan_term,
          a.original_ltv,
          a.debt_to_income,
          a.number_of_borrowers,
          a.borrower_credit_score_at_orig as orig_fico
                label='Borrower Credit Score at Origination',

          b.first_rpt_dt,
          b.last_rpt_dt,
          b.months_observed,
          b.ever_d90,
          b.first_d90_dt,
          b.max_dlq,
          b.last_zb_code,
          b.default_flag,

          /* MIGRATION NOTE - missing-value ordering in PROC SQL.
             PROC SQL uses SAS comparison rules, not ANSI SQL: a
             missing credit score is LESS THAN 620, so loans with no
             score are flagged subprime 'Y'. Spark SQL evaluates
             NULL < 620 as NULL, the WHEN fails, and they get 'N'.
             To match SAS, write
               WHEN orig_fico IS NULL OR orig_fico < 620 THEN 'Y'.    */
          case when a.borrower_credit_score_at_orig < 620 then 'Y'
               else 'N'
          end as subprime_flag length=1,

          /* MIGRATION NOTE - correlated subquery.
             Runs once per outer row: the current UPB in the month the
             loan first went 90+ days delinquent.
             SAS-specific behaviour to preserve or consciously change:
             1. No matching row -> missing (Spark: NULL, same).
             2. More than one matching row -> PROC SQL stops with
                "ERROR: Subquery evaluated to more than one row."
                The pre-aggregated LEFT JOIN that replaces it (see
                the index note at the top) would silently duplicate
                the loan instead.
             3. For a loan that never hit 90 days, first_d90_dt is
                missing, and in SAS  missing = missing  is TRUE. If the
                loan has a row with a missing rpt_dt, the subquery
                MATCHES it and returns that row's UPB (or errors if
                there are several). In Spark NULL = NULL is NULL, so
                it returns NULL. Use <=> only if the SAS behaviour is
                actually wanted.
             Note also that current_actual_upb is 0 for a loan's first
             months in the Fannie Mae file, so an early 90+ event can
             report a zero UPB.                                       */
          (select c.current_actual_upb
             from fmlib.lp_perf c
            where c.loan_identifier = b.loan_identifier
              and c.rpt_dt          = b.first_d90_dt)
             as upb_at_first_d90 format=comma14.2,

          /* Second correlated subquery: months at 30+ days, using the
             carried-forward status from 03.                           */
          (select count(*)
             from fmlib.lp_perf d
            where d.loan_identifier = a.loan_identifier
              and d.dlq_filled >= 1)
             as months_30plus,

          /* CALCULATED is a PROC SQL extension: it reuses an alias
             defined earlier in the same SELECT. Databricks SQL
             allows the bare alias (lateral column alias) with no
             keyword; in PySpark, chain a second withColumn.
             Division by zero gives missing in SAS. In Spark it gives
             NULL with ANSI mode off and an ERROR with ANSI mode on.  */
          calculated upb_at_first_d90 / a.original_upb
             as pct_upb_at_first_d90 format=percent8.2

     /* MIGRATION NOTE - implicit join.
        Comma-separated tables with the join condition in WHERE is an
        implicit INNER join. Consequences to reproduce in Spark:
        - a loan present in only one table silently disappears from
          the ABT (no row, no warning);
        - if a loan has two rows with the same rpt_dt (duplicate
          monthly records), it FANS OUT into two ABT rows and the
          "one row per loan" grain breaks with no message;
        - a.rpt_dt = b.first_rpt_dt uses SAS equality, so if a loan's
          first sorted row had a missing rpt_dt (see 03), missing =
          missing matches here. Spark's = drops that loan instead.
        Write it as an explicit INNER JOIN ... ON in Spark and add a
        grain check (count = count distinct loan_identifier).        */
     from fmlib.lp_perf  a,
          fmlib.loan_perf b
    where a.loan_identifier = b.loan_identifier
      and a.rpt_dt          = b.first_rpt_dt
    order by a.loan_identifier;
quit;
