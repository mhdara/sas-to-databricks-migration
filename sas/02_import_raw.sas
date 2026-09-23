/*********************************************************************
*  PROGRAM : 02_import_raw.sas
*  PURPOSE : Read the raw pipe-delimited loan performance file into
*            FMLIB.LP_RAW, one observation per loan per month.
*  INPUT   : &raw_file  (113 columns, no header row)
*  OUTPUT  : FMLIB.LP_RAW
*  RUN     : After 01_setup_libname.sas.
*
*  Column order follows docs/file_layout.md. Names longer than the
*  SAS 32-character limit are abbreviated; the layout name is in the
*  comment on that line. Every line carries its ordinal position.
*
*  NOTE    : Representative legacy program written for the
*            SAS-to-Databricks migration project.
*********************************************************************/

/*-------------------------------------------------------------------
  Utility: convert an MMYYYY character field to a SAS date on the
  1st of that month. Blank input yields a missing date (and a
  "Missing values were generated" NOTE in the log).
-------------------------------------------------------------------*/
%macro mmyyyy_to_date(charvar);
   mdy(input(substr(&charvar,1,2),2.), 1, input(substr(&charvar,3,4),4.))
%mend mmyyyy_to_date;

data fmlib.lp_raw;

   /* MIGRATION NOTE - INFILE options.
      DLM='|' DSD : pipe-delimited; DSD makes two adjacent pipes a
                    missing value (instead of collapsing them) and
                    treats a field wrapped in double quotes as quoted.
      MISSOVER    : a short record does NOT pull values from the next
                    line; the missing tail columns are set to missing.
                    A truncated record therefore loads silently with
                    blank trailing columns instead of being rejected.
                    Spark's CSV reader (PERMISSIVE) behaves the same
                    way, so Bronze needs an explicit field-count check
                    to route short rows to quarantine.
      LRECL=1024  : longest 2007Q1 record is 396 bytes. A record longer
                    than LRECL is truncated, not rejected.            */
   infile "&raw_file" dlm='|' dsd missover lrecl=1024;

   /* MIGRATION NOTE - numeric fields and bad data.
      Numeric columns use list input with no informat. A malformed
      value (e.g. "12O.5") produces "NOTE: Invalid data for ...",
      sets _ERROR_=1, and the variable becomes MISSING. The row is
      still written. SAS silently nulls bad values - the Bronze layer
      reads everything as strings and Silver quarantines them instead.

      Character fields are fixed length: a value longer than the
      declared width (e.g. seller_name > 60 chars) is truncated with
      no message.                                                     */
   input
   reference_pool_id                : $10.  /* 001 */
   loan_identifier                  : $12.  /* 002 */
   monthly_reporting_period         : $6.   /* 003 MMYYYY */
   channel                          : $1.   /* 004 */
   seller_name                      : $60.  /* 005 */
   servicer_name                    : $60.  /* 006 */
   master_servicer                  : $60.  /* 007 */
   original_interest_rate                   /* 008 */
   current_interest_rate                    /* 009 */
   original_upb                             /* 010 */
   upb_at_issuance                          /* 011 */
   current_actual_upb                       /* 012 */
   original_loan_term                       /* 013 */
   origination_date                 : $6.   /* 014 MMYYYY */
   first_payment_date               : $6.   /* 015 MMYYYY */
   loan_age                                 /* 016 */
   rem_months_to_legal_maturity             /* 017 remaining_months_to_legal_maturity */
   remaining_months_to_maturity             /* 018 */
   maturity_date                    : $6.   /* 019 MMYYYY */
   original_ltv                             /* 020 */
   original_cltv                            /* 021 */
   number_of_borrowers                      /* 022 */
   debt_to_income                           /* 023 */
   borrower_credit_score_at_orig            /* 024 borrower_credit_score_at_origination */
   co_borrower_credit_score_at_orig         /* 025 co_borrower_credit_score_at_origination */
   first_time_home_buyer_indicator  : $1.   /* 026 */
   loan_purpose                     : $1.   /* 027 */
   property_type                    : $2.   /* 028 */
   number_of_units                          /* 029 */
   occupancy_status                 : $1.   /* 030 */
   property_state                   : $2.   /* 031 */
   msa                              : $5.   /* 032 */
   zip_code_short                   : $3.   /* 033 */
   mortgage_insurance_percentage            /* 034 */
   amortization_type                : $3.   /* 035 */
   prepayment_penalty_indicator     : $1.   /* 036 */
   interest_only_loan_indicator     : $1.   /* 037 */
   io_first_p_and_i_payment_date    : $6.   /* 038 MMYYYY interest_only_first_principal_and_interest_payment_date */
   months_to_amortization                   /* 039 */
   current_loan_delinquency_status  : $3.   /* 040 */
   loan_payment_history             : $48.  /* 041 */
   modification_flag                : $1.   /* 042 */
   mi_cancellation_indicator        : $1.   /* 043 mortgage_insurance_cancellation_indicator */
   zero_balance_code                : $3.   /* 044 */
   zero_balance_effective_date      : $6.   /* 045 MMYYYY */
   upb_at_the_time_of_removal               /* 046 */
   repurchase_date                  : $6.   /* 047 MMYYYY */
   scheduled_principal_current              /* 048 */
   total_principal_current                  /* 049 */
   unscheduled_principal_current            /* 050 */
   last_paid_installment_date       : $6.   /* 051 MMYYYY */
   foreclosure_date                 : $6.   /* 052 MMYYYY */
   disposition_date                 : $6.   /* 053 MMYYYY */
   foreclosure_costs                        /* 054 */
   property_preserv_repair_costs            /* 055 property_preservation_and_repair_costs */
   asset_recovery_costs                     /* 056 */
   misc_holding_expenses_credits            /* 057 miscellaneous_holding_expenses_and_credits */
   assoc_taxes_holding_property             /* 058 associated_taxes_for_holding_property */
   net_sales_proceeds                       /* 059 */
   credit_enhancement_proceeds              /* 060 */
   repurchase_make_whole_proceeds           /* 061 */
   other_foreclosure_proceeds               /* 062 */
   mod_related_non_int_bearing_upb          /* 063 modification_related_non_interest_bearing_upb */
   principal_forgiveness_amount             /* 064 */
   original_list_start_date         : $6.   /* 065 MMYYYY */
   original_list_price                      /* 066 */
   current_list_start_date          : $6.   /* 067 MMYYYY */
   current_list_price                       /* 068 */
   borrower_credit_score_at_issue           /* 069 borrower_credit_score_at_issuance */
   co_borrower_credit_score_at_iss          /* 070 co_borrower_credit_score_at_issuance */
   borrower_credit_score_current            /* 071 */
   co_borrower_credit_score_current         /* 072 */
   mortgage_insurance_type          : $1.   /* 073 */
   servicing_activity_indicator     : $1.   /* 074 */
   curr_period_mod_loss_amount              /* 075 current_period_modification_loss_amount */
   cumulative_mod_loss_amount               /* 076 cumulative_modification_loss_amount */
   curr_period_credit_evt_net_gl            /* 077 current_period_credit_event_net_gain_or_loss */
   cumulative_credit_evt_net_gl             /* 078 cumulative_credit_event_net_gain_or_loss */
   special_eligibility_program      : $1.   /* 079 */
   fcl_principal_write_off_amount           /* 080 foreclosure_principal_write_off_amount */
   relocation_mortgage_indicator    : $1.   /* 081 */
   zero_balance_code_change_date    : $6.   /* 082 MMYYYY */
   loan_holdback_indicator          : $1.   /* 083 */
   loan_holdback_effective_date     : $6.   /* 084 MMYYYY */
   delinquent_accrued_interest              /* 085 */
   property_valuation_method        : $1.   /* 086 */
   high_balance_loan_indicator      : $1.   /* 087 */
   arm_init_fixed_le_5yr_indicator  : $1.   /* 088 arm_initial_fixed_rate_period_le_5_yr_indicator */
   arm_product_type                 : $100. /* 089 */
   initial_fixed_rate_period                /* 090 */
   int_rate_adjustment_frequency            /* 091 interest_rate_adjustment_frequency */
   next_int_rate_adjustment_date    : $6.   /* 092 MMYYYY next_interest_rate_adjustment_date */
   next_payment_change_date         : $6.   /* 093 MMYYYY */
   index                            : $100. /* 094 */
   arm_cap_structure                : $10.  /* 095 */
   initial_int_rate_cap_up_pct              /* 096 initial_interest_rate_cap_up_percent */
   periodic_int_rate_cap_up_pct             /* 097 periodic_interest_rate_cap_up_percent */
   lifetime_int_rate_cap_up_pct             /* 098 lifetime_interest_rate_cap_up_percent */
   mortgage_margin                          /* 099 */
   arm_balloon_indicator            : $1.   /* 100 */
   arm_plan_number                          /* 101 */
   borrower_assistance_plan         : $1.   /* 102 */
   hltv_refinance_option_indicator  : $1.   /* 103 */
   deal_name                        : $40.  /* 104 */
   repurchase_make_whole_proc_flag  : $1.   /* 105 repurchase_make_whole_proceeds_flag */
   alt_delinquency_resolution       : $1.   /* 106 alternative_delinquency_resolution */
   alt_delinquency_resolution_cnt           /* 107 alternative_delinquency_resolution_count */
   total_deferral_amount                    /* 108 */
   pmt_deferral_mod_event_ind       : $1.   /* 109 payment_deferral_modification_event_indicator */
   interest_bearing_upb                     /* 110 */
   origination_classic_fico                 /* 111 */
   issuance_classic_fico                    /* 112 */
   current_classic_fico                     /* 113 */
   ;

   /*--- derived SAS dates for the fields the suite uses ------------*/
   /* The raw MMYYYY strings are kept alongside for audit.            */
   rpt_dt       = %mmyyyy_to_date(monthly_reporting_period);
   orig_dt      = %mmyyyy_to_date(origination_date);
   first_pay_dt = %mmyyyy_to_date(first_payment_date);
   maturity_dt  = %mmyyyy_to_date(maturity_date);
   zb_dt        = %mmyyyy_to_date(zero_balance_effective_date);
   fcl_dt       = %mmyyyy_to_date(foreclosure_date);

   /* MIGRATION NOTE - FORMAT vs stored value (dates).
      The stored value of rpt_dt etc. is a NUMBER: days since
      01JAN1960, always the 1st of the month (e.g. FEB2007 = 17198).
      MONYY7. only changes how it displays ("FEB2007"). Any output
      that shows a date is showing the formatted value; the join and
      sort logic runs on the day count. In Spark, use DateType built
      with to_date(concat(...), 'MMyyyy'), which also lands on the
      1st of the month.                                               */
   format rpt_dt orig_dt first_pay_dt maturity_dt zb_dt fcl_dt monyy7.
          original_upb current_actual_upb           comma14.2
          original_interest_rate current_interest_rate 6.3;

   label loan_identifier                = 'Loan Identifier'
         monthly_reporting_period       = 'Monthly Reporting Period (MMYYYY)'
         rpt_dt                         = 'Reporting Period'
         orig_dt                        = 'Origination Date'
         original_upb                   = 'Original UPB'
         current_actual_upb             = 'Current Actual UPB'
         original_interest_rate         = 'Original Interest Rate'
         borrower_credit_score_at_orig  = 'Borrower Credit Score at Origination'
         original_ltv                   = 'Original LTV'
         debt_to_income                 = 'Debt-to-Income Ratio'
         property_state                 = 'Property State'
         current_loan_delinquency_status = 'Current Loan Delinquency Status'
         zero_balance_code              = 'Zero Balance Code'
         foreclosure_date               = 'Foreclosure Date (MMYYYY)';
run;
