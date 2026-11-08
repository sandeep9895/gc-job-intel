-- Check the training table
SELECT
  COUNT(*) AS total_rows,
  COUNTIF(is_stale) AS stale_rows,
  ROUND(100 * COUNTIF(is_stale) / COUNT(*), 2) AS pct_stale,
  COUNTIF(company_stale_rate_loo IS NULL) AS rows_without_company_rate
FROM `gc-job-intel.jobs_curated.ghost_training`;
