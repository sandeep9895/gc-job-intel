-- Submit and query
SELECT skill_a, skill_b, postings
FROM `gc-job-intel.jobs_curated.skill_pairs`
ORDER BY postings DESC
LIMIT 15;
