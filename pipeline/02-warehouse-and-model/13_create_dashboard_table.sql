-- 13 – Dashboard table (`13_create_dashboard_table`)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.dashboard_postings` AS
SELECT
  p.job_id,
  p.company_name,
  p.title,
  p.experience_level,
  p.work_type,
  p.is_remote,
  p.application_type,
  p.listed_date,
  p.days_open,
  CASE
    WHEN p.days_open = 0 THEN '1. Same day'
    WHEN p.days_open <= 7 THEN '2. 1-7 days'
    WHEN p.days_open <= 30 THEN '3. 8-30 days'
    ELSE '4. 30+ days'
  END AS days_open_bucket,
  p.views,
  p.applies,
  IF(p.applies IS NOT NULL, p.views, NULL) AS views_with_apply_data,
  p.normalized_salary,
  s.stale_score,
  s.risk_tier,
  s.actual_is_stale
FROM `gc-job-intel.jobs_curated.postings` p
LEFT JOIN `gc-job-intel.jobs_curated.posting_scores` s USING (job_id);
