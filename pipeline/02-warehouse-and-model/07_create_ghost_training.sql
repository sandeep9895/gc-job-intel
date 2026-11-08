-- 07 – Create the training table (`07_create_ghost_training`)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.ghost_training` AS
WITH base AS (
  SELECT
    job_id,
    company_name,
    days_open > 7 AS is_stale,
    experience_level,
    work_type,
    is_remote,
    application_type,
    normalized_salary IS NOT NULL AS has_salary,
    LENGTH(description) AS description_length,
    REGEXP_CONTAINS(LOWER(title), r'senior|sr\.|lead|principal|staff') AS is_senior_title
  FROM `gc-job-intel.jobs_curated.postings`
),
company_totals AS (
  SELECT
    company_name,
    COUNT(*) AS n_postings,
    COUNTIF(is_stale) AS n_stale
  FROM base
  WHERE company_name IS NOT NULL
  GROUP BY company_name
)
SELECT
  b.*,
  c.n_postings - 1 AS company_other_postings,
  SAFE_DIVIDE(c.n_stale - IF(b.is_stale, 1, 0), c.n_postings - 1) AS company_stale_rate_loo
FROM base b
LEFT JOIN company_totals c USING (company_name);
