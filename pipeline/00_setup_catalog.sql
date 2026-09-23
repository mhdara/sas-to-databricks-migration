-- Unity Catalog structure for the SAS migration project.
-- Run once per workspace before any pipeline code.

CREATE CATALOG IF NOT EXISTS mortgage_analytics;
USE CATALOG mortgage_analytics;

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE SCHEMA IF NOT EXISTS quarantine;
CREATE SCHEMA IF NOT EXISTS reconciliation;

CREATE VOLUME IF NOT EXISTS bronze.landing;