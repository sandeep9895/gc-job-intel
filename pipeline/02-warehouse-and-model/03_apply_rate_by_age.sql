-- 03 – Apply rate by posting age (saved as `03_apply_rate_by_age`)
SELECT
  CASE
    WHEN days_open = 0 THEN '1. Same day'
    WHEN days_open <= 7 THEN '2. 1-7 days'
    WHEN days_open <= 30 THEN '3. 8-30 days'
    ELSE '4. 30+ days'
  END AS days_open_bucket,
  COUNT(*) AS postings_with_applies,
  ROUND(AVG(views), 1) AS avg_views,
  ROUND(AVG(applies), 1) AS avg_applies,
  ROUND(100 * SAFE_DIVIDE(SUM(applies), SUM(views)), 1) AS apply_rate_pct
FROM `gc-job-intel.jobs_curated.postings`
WHERE applies IS NOT NULL
  AND views > 0
GROUP BY days_open_bucket
ORDER BY days_open_bucket;
