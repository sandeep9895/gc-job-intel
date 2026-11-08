-- 15 – Tag postings with skills (`15_create_posting_skills`)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.posting_skills` AS
SELECT p.job_id, d.skill, d.category
FROM `gc-job-intel.jobs_curated.postings` p
CROSS JOIN `gc-job-intel.jobs_curated.skill_dictionary` d
WHERE REGEXP_CONTAINS(LOWER(p.description), d.pattern);
