-- 19 / 20 – Stream checks
SELECT risk_tier, COUNT(*) AS postings
FROM `gc-job-intel.jobs_curated.stream_scored`
GROUP BY risk_tier ORDER BY risk_tier;

SELECT title, company_name, stale_score, risk_tier, sent_at
FROM `gc-job-intel.jobs_curated.stream_scored`
ORDER BY stale_score DESC LIMIT 10;
