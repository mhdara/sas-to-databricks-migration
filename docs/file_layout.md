# Fannie Mae Single-Family Loan Performance — File Layout

Source: [SF Glossary & File Layout (PDF)](https://capitalmarkets.fanniemae.com/resources/file/credit-risk/pdf/crt-file-layout-and-glossary.pdf)

Files are pipe-delimited (`|`) with **no header row**. Columns are identified by ordinal position.

**Our files contain columns 1–113.** The published layout also defines column 114 (Origination VantageScore® 4.0), which is absent from the downloaded files. Verified on 2007Q1 and 2025Q1–Q4: all report 113 fields.

Alignment validated against known-format fields: position 31 yields valid US state codes, position 40 yields valid delinquency status codes.

Dates arrive as `MMYYYY` strings.

| # | Column name | Type |
|---|---|---|
| 1 | reference_pool_id | string |
| 2 | loan_identifier | string |
| 3 | monthly_reporting_period | date (MMYYYY) |
| 4 | channel | string |
| 5 | seller_name | string |
| 6 | servicer_name | string |
| 7 | master_servicer | string |
| 8 | original_interest_rate | numeric |
| 9 | current_interest_rate | numeric |
| 10 | original_upb | numeric |
| 11 | upb_at_issuance | numeric |
| 12 | current_actual_upb | numeric |
| 13 | original_loan_term | numeric |
| 14 | origination_date | date (MMYYYY) |
| 15 | first_payment_date | date (MMYYYY) |
| 16 | loan_age | numeric |
| 17 | remaining_months_to_legal_maturity | numeric |
| 18 | remaining_months_to_maturity | numeric |
| 19 | maturity_date | date (MMYYYY) |
| 20 | original_ltv | numeric |
| 21 | original_cltv | numeric |
| 22 | number_of_borrowers | numeric |
| 23 | debt_to_income | numeric |
| 24 | borrower_credit_score_at_origination | numeric |
| 25 | co_borrower_credit_score_at_origination | numeric |
| 26 | first_time_home_buyer_indicator | string |
| 27 | loan_purpose | string |
| 28 | property_type | string |
| 29 | number_of_units | numeric |
| 30 | occupancy_status | string |
| 31 | property_state | string |
| 32 | msa | string |
| 33 | zip_code_short | string |
| 34 | mortgage_insurance_percentage | numeric |
| 35 | amortization_type | string |
| 36 | prepayment_penalty_indicator | string |
| 37 | interest_only_loan_indicator | string |
| 38 | interest_only_first_principal_and_interest_payment_date | date (MMYYYY) |
| 39 | months_to_amortization | numeric |
| 40 | current_loan_delinquency_status | string |
| 41 | loan_payment_history | string |
| 42 | modification_flag | string |
| 43 | mortgage_insurance_cancellation_indicator | string |
| 44 | zero_balance_code | string |
| 45 | zero_balance_effective_date | date (MMYYYY) |
| 46 | upb_at_the_time_of_removal | numeric |
| 47 | repurchase_date | date (MMYYYY) |
| 48 | scheduled_principal_current | numeric |
| 49 | total_principal_current | numeric |
| 50 | unscheduled_principal_current | numeric |
| 51 | last_paid_installment_date | date (MMYYYY) |
| 52 | foreclosure_date | date (MMYYYY) |
| 53 | disposition_date | date (MMYYYY) |
| 54 | foreclosure_costs | numeric |
| 55 | property_preservation_and_repair_costs | numeric |
| 56 | asset_recovery_costs | numeric |
| 57 | miscellaneous_holding_expenses_and_credits | numeric |
| 58 | associated_taxes_for_holding_property | numeric |
| 59 | net_sales_proceeds | numeric |
| 60 | credit_enhancement_proceeds | numeric |
| 61 | repurchase_make_whole_proceeds | numeric |
| 62 | other_foreclosure_proceeds | numeric |
| 63 | modification_related_non_interest_bearing_upb | numeric |
| 64 | principal_forgiveness_amount | numeric |
| 65 | original_list_start_date | date (MMYYYY) |
| 66 | original_list_price | numeric |
| 67 | current_list_start_date | date (MMYYYY) |
| 68 | current_list_price | numeric |
| 69 | borrower_credit_score_at_issuance | numeric |
| 70 | co_borrower_credit_score_at_issuance | numeric |
| 71 | borrower_credit_score_current | numeric |
| 72 | co_borrower_credit_score_current | numeric |
| 73 | mortgage_insurance_type | string |
| 74 | servicing_activity_indicator | string |
| 75 | current_period_modification_loss_amount | numeric |
| 76 | cumulative_modification_loss_amount | numeric |
| 77 | current_period_credit_event_net_gain_or_loss | numeric |
| 78 | cumulative_credit_event_net_gain_or_loss | numeric |
| 79 | special_eligibility_program | string |
| 80 | foreclosure_principal_write_off_amount | numeric |
| 81 | relocation_mortgage_indicator | string |
| 82 | zero_balance_code_change_date | date (MMYYYY) |
| 83 | loan_holdback_indicator | string |
| 84 | loan_holdback_effective_date | date (MMYYYY) |
| 85 | delinquent_accrued_interest | numeric |
| 86 | property_valuation_method | string |
| 87 | high_balance_loan_indicator | string |
| 88 | arm_initial_fixed_rate_period_le_5_yr_indicator | string |
| 89 | arm_product_type | string |
| 90 | initial_fixed_rate_period | numeric |
| 91 | interest_rate_adjustment_frequency | numeric |
| 92 | next_interest_rate_adjustment_date | date (MMYYYY) |
| 93 | next_payment_change_date | date (MMYYYY) |
| 94 | index | string |
| 95 | arm_cap_structure | string |
| 96 | initial_interest_rate_cap_up_percent | numeric |
| 97 | periodic_interest_rate_cap_up_percent | numeric |
| 98 | lifetime_interest_rate_cap_up_percent | numeric |
| 99 | mortgage_margin | numeric |
| 100 | arm_balloon_indicator | string |
| 101 | arm_plan_number | numeric |
| 102 | borrower_assistance_plan | string |
| 103 | hltv_refinance_option_indicator | string |
| 104 | deal_name | string |
| 105 | repurchase_make_whole_proceeds_flag | string |
| 106 | alternative_delinquency_resolution | string |
| 107 | alternative_delinquency_resolution_count | numeric |
| 108 | total_deferral_amount | numeric |
| 109 | payment_deferral_modification_event_indicator | string |
| 110 | interest_bearing_upb | numeric |
| 111 | origination_classic_fico | numeric |
| 112 | issuance_classic_fico | numeric |
| 113 | current_classic_fico | numeric |

## Columns this project uses

Everything above is ingested into Bronze. These are the ones Silver and Gold work with.

| # | Column | Role in this project |
|---|---|---|
| 2 | loan_identifier | Primary key part 1 |
| 3 | monthly_reporting_period | Primary key part 2 |
| 8 | original_interest_rate | Loan characteristic |
| 10 | original_upb | Loan size |
| 12 | current_actual_upb | Current balance |
| 14 | origination_date | Derives the vintage quarter |
| 16 | loan_age | Months on book |
| 20 | original_ltv | Risk factor |
| 23 | debt_to_income | Risk factor |
| 24 | borrower_credit_score_at_origination | Credit score bands |
| 27 | loan_purpose | Purchase vs refinance |
| 31 | property_state | By-state Gold table |
| **40** | **current_loan_delinquency_status** | **The core column.** Changes month over month per loan. The SAS RETAIN / BY-group logic tracks it; the PySpark window function replaces that logic; the default rate is derived from it |
| 44 | zero_balance_code | How the loan ended (paid off, foreclosed) |
| 52 | foreclosure_date | Confirms default |
