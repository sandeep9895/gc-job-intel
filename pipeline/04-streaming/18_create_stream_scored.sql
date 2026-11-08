-- 18 – Real-time scoring view (`18_create_stream_scored`)
CREATE OR REPLACE VIEW `gc-job-intel.jobs_curated.stream_scored` AS
WITH company_history AS (
  SELECT company_name,
         COUNT(*) AS n_postings,
         AVG(IF(is_stale, 1, 0)) AS stale_rate
  FROM `gc-job-intel.jobs_curated.ghost_training`
  WHERE company_name IS NOT NULL
  GROUP BY company_name
),
features AS (
  SELECT
    s.job_id, s.title, s.company_name, s.sent_at,
    s.experience_level, s.work_type, s.is_remote, s.application_type,
    s.normalized_salary IS NOT NULL AS has_salary,
    LENGTH(s.description) AS description_length,
    REGEXP_CONTAINS(LOWER(s.title), r'senior|sr\.|lead|principal|staff') AS is_senior_title,
    h.n_postings AS company_other_postings,
    h.stale_rate AS company_stale_rate_loo
  FROM `gc-job-intel.jobs_raw.postings_stream` s
  LEFT JOIN company_history h USING (company_name)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY s.job_id ORDER BY s.sent_at DESC) = 1
)
SELECT
  job_id, title, company_name, sent_at,
  ROUND(p.prob, 3) AS stale_score,
  CASE
    WHEN p.prob >= 0.99 THEN '1. High'
    WHEN p.prob >= 0.74 THEN '2. Medium'
    ELSE '3. Low'
  END AS risk_tier
FROM ML.PREDICT(
  MODEL `gc-job-intel.jobs_curated.ghost_model_v1`,
  (SELECT * FROM features)),
UNNEST(predicted_is_stale_probs) AS p
WHERE p.label = TRUE;
