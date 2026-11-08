-- Check the curated table (not saved)
SELECT
  COUNT(*) AS rows_curated,
  COUNTIF(is_reposted) AS reposted,
  APPROX_QUANTILES(days_open, 4) AS days_open_quartiles,
  MAX(days_open) AS max_days_open
FROM `gc-job-intel.jobs_curated.postings`;
