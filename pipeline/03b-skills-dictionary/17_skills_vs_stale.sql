-- 17 – Skills vs stale postings (`17_skills_vs_stale`)
SELECT
  s.skill,
  s.category,
  COUNT(*) AS postings,
  ROUND(100 * COUNTIF(sc.actual_is_stale) / COUNT(*), 2) AS pct_stale,
  ROUND(100 * SAFE_DIVIDE(SUM(p.applies),
        SUM(IF(p.applies IS NOT NULL, p.views, 0))), 1) AS apply_rate_pct
FROM `gc-job-intel.jobs_curated.posting_skills` s
JOIN `gc-job-intel.jobs_curated.posting_scores` sc USING (job_id)
JOIN `gc-job-intel.jobs_curated.postings` p USING (job_id)
GROUP BY s.skill, s.category
HAVING postings >= 500
ORDER BY pct_stale DESC;
