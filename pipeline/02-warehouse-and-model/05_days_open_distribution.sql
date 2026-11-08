-- 05 – Days-open distribution (not saved)
SELECT
  CASE
    WHEN days_open = 0 THEN '1. Same day'
    WHEN days_open <= 7 THEN '2. 1-7 days'
    WHEN days_open <= 30 THEN '3. 8-30 days'
    WHEN days_open <= 60 THEN '4. 31-60 days'
    ELSE '5. 60+ days'
  END AS days_open_bucket,
  COUNT(*) AS postings,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct,
  ROUND(AVG(views), 1) AS avg_views,
  ROUND(AVG(applies), 1) AS avg_applies
FROM `gc-job-intel.jobs_curated.postings`
GROUP BY days_open_bucket
ORDER BY days_open_bucket;
