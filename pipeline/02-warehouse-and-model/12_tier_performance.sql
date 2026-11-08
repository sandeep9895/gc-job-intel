-- 12 – Tier performance (`12_tier_performance`)
SELECT
  risk_tier,
  COUNT(*) AS postings,
  ROUND(100 * COUNTIF(actual_is_stale) / COUNT(*), 1) AS pct_actually_stale
FROM `gc-job-intel.jobs_curated.posting_scores`
GROUP BY risk_tier
ORDER BY risk_tier;
