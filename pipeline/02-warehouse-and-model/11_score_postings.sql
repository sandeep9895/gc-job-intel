-- 11 – Score every posting (`11_score_postings`)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.posting_scores` AS
SELECT
  job_id,
  company_name,
  is_stale AS actual_is_stale,
  p.prob AS stale_score,
  CASE
    WHEN p.prob >= 0.99 THEN '1. High'
    WHEN p.prob >= 0.74 THEN '2. Medium'
    ELSE '3. Low'
  END AS risk_tier
FROM ML.PREDICT(
  MODEL `gc-job-intel.jobs_curated.ghost_model_v1`,
  (SELECT * FROM `gc-job-intel.jobs_curated.ghost_training`)),
UNNEST(predicted_is_stale_probs) AS p
WHERE p.label = TRUE;
