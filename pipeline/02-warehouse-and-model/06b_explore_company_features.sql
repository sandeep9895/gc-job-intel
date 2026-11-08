-- Explore company features (not saved)
SELECT *
FROM `gc-job-intel.jobs_curated.company_features`
WHERE total_postings >= 20
ORDER BY pct_long_open DESC
LIMIT 20;
