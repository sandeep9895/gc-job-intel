-- 02 – Ghost-job signals on raw data (not saved)
SELECT
  COUNTIF(listed_time > original_listed_time) AS reposted_listings,
  ROUND(100 * COUNTIF(listed_time > original_listed_time) / COUNT(*), 1) AS pct_reposted,
  DATE(TIMESTAMP_MILLIS(CAST(MIN(original_listed_time) AS INT64))) AS earliest_original_listing,
  ROUND(AVG(views), 1) AS avg_views,
  ROUND(AVG(applies), 1) AS avg_applies,
  COUNTIF(applies IS NULL) AS postings_without_apply_data
FROM `gc-job-intel.jobs_raw.postings`;
