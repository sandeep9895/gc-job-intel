-- 16 – Top skills (`16_top_skills`)
SELECT
  skill,
  category,
  COUNT(*) AS postings,
  ROUND(100 * COUNT(*) / 123849, 1) AS pct_of_postings
FROM `gc-job-intel.jobs_curated.posting_skills`
GROUP BY skill, category
ORDER BY postings DESC
LIMIT 25;
