-- 01 – Profile the raw data (not saved)
SELECT
  COUNT(*) AS total_postings,
  COUNT(DISTINCT company_name) AS companies,
  DATE(TIMESTAMP_MILLIS(CAST(MIN(listed_time) AS INT64))) AS earliest_listed,
  DATE(TIMESTAMP_MILLIS(CAST(MAX(listed_time) AS INT64))) AS latest_listed
FROM `gc-job-intel.jobs_raw.postings`;
