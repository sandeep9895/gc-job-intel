-- 06 – Create company features (saved as `06_create_company_features`)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.company_features` AS
SELECT
  company_name,
  COUNT(*) AS total_postings,
  COUNTIF(days_open > 7) AS long_open_postings,
  ROUND(100 * COUNTIF(days_open > 7) / COUNT(*), 1) AS pct_long_open,
  ROUND(AVG(days_open), 1) AS avg_days_open,
  MAX(days_open) AS max_days_open,
  COUNTIF(applies IS NOT NULL) AS postings_with_apply_data,
  ROUND(100 * SAFE_DIVIDE(
    SUM(applies),
    SUM(IF(applies IS NOT NULL, views, 0))), 1) AS apply_rate_pct,
  ROUND(AVG(views), 1) AS avg_views
FROM `gc-job-intel.jobs_curated.postings`
WHERE company_name IS NOT NULL
GROUP BY company_name;
