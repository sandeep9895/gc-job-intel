-- 10 – Threshold analysis (`10_threshold_analysis`)
SELECT
  ROUND(threshold, 2) AS threshold,
  ROUND(recall, 3) AS recall,
  ROUND(SAFE_DIVIDE(true_positives, true_positives + false_positives), 3) AS precision,
  true_positives + false_positives AS postings_flagged
FROM ML.ROC_CURVE(MODEL `gc-job-intel.jobs_curated.ghost_model_v1`)
WHERE threshold >= 0.5
ORDER BY threshold;
