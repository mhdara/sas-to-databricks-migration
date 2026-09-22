# CLAUDE.md

## Project
Portfolio project migrating a legacy SAS mortgage-analytics workload to Databricks,
using the Fannie Mae Single-Family Loan Performance dataset. The goal is proving the
new pipeline reproduces the SAS outputs, via a parallel-run reconciliation.

## Structure
- `data/` — raw Fannie Mae downloads. NEVER commit; gitignored (license forbids redistribution)
- `sas/` — legacy SAS programs (the migration source) and their output CSVs (ground truth)
- `pipeline/` — Databricks code: `schema.py`, `bronze_ingest.py`, `silver_build.py`, `reconcile.py`
- `dbt/` — dbt Core project building the Gold layer
- `tests/` — pytest unit tests; must run locally without a Databricks connection
- `docs/` — architecture doc, decision records (`docs/adr/`), screenshots (`docs/images/`)
- `databricks.yml` — deployment config for the job

## Data facts
- Source files are pipe-delimited (`|`) with NO header row; columns are identified by position
- Layout is defined in the official Fannie Mae file layout spreadsheet
- Unity Catalog: catalog `mortgage_analytics`, schemas `bronze`, `silver`, `gold`, `quarantine`, `reconciliation`
- Landing zone is a UC Volume: `/Volumes/mortgage_analytics/bronze/landing/loan_performance/`
  (Databricks Free Edition has no external S3 access; S3 is the documented production design)

## Rules
- Bronze is append-only: no casting, filtering, deduplication or business logic
- Bad rows go to the `quarantine` schema with a reason column — never silently drop or null them
- snake_case for all column and table names
- Pipeline files are Databricks notebooks as `.py` with `# COMMAND ----------` cell separators
- Every dbt model starts with a comment naming the SAS program it replaces
- Before translating any SAS logic, read `docs/SAS_TRANSLATION_NOTES.md` (once it exists).
  Watch for: RETAIN / BY-group state, SAS missing values sorting below all numbers,
  implicit PROC SQL joins, FORMAT vs stored value
- Never write secrets, tokens or workspace URLs into any file in this repo

## Naming (current Databricks terms)
- Lakeflow pipelines (not Delta Live Tables); Python API `from pyspark import pipelines as dp`
- Lakeflow Jobs (not Workflows)
- Declarative Automation Bundles (not Databricks Asset Bundles)

## Environment
- macOS; Python 3.11 venv at `.venv` — activate with `source .venv/bin/activate`
- Databricks CLI authenticated via OAuth (`databricks auth login`)