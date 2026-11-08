-- History table
CREATE TABLE IF NOT EXISTS `gc-job-intel.jobs_curated.daily_risk_snapshot` (
  snapshot_date DATE,
  risk_tier STRING,
  postings INT64
);
