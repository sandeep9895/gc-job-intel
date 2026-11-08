-- Build 1, Phase 2: Gemini skills extraction over 20 real job postings (BigQuery editor)
-- Result: 0 API errors, 0 parse failures, 5.7 skills per posting.

-- Query A: pick 20 postings and freeze them (FARM_FINGERPRINT gives a repeatable order)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build1_sample` AS
SELECT job_id, company_name, title, description
FROM `gc-job-intel.jobs_curated.postings`
WHERE description IS NOT NULL
  AND LENGTH(description) > 300
ORDER BY FARM_FINGERPRINT(CAST(job_id AS STRING))
LIMIT 20;

-- Query B: one-shot JSON extraction prompt, temperature 0
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build1_extractions` AS
SELECT *
FROM ML.GENERATE_TEXT(
  MODEL `gc-job-intel.jobs_curated.gemini_flash`,
  (
    SELECT
      job_id,
      title,
      CONCAT('''You extract structured data from job postings.
Return ONLY valid JSON with exactly these keys:
- "skills": array of up to 15 concrete skills, tools or technologies named in the posting, in their common short form (e.g. "SQL", "Python", "Salesforce"). Exclude soft skills.
- "seniority": one of "Intern", "Entry", "Mid", "Senior", "Lead", "Manager", "Director+", "Not found".
- "years_experience": minimum years required as written (e.g. "3+", "2-4"), or "Not found".
Use only information in the posting. Never guess.

Example posting:
Title: Senior Data Engineer
Description: 5+ years building pipelines in Python and SQL. Airflow, Spark and AWS required. Snowflake a plus.
Example output:
{"skills": ["Python", "SQL", "Airflow", "Spark", "AWS", "Snowflake"], "seniority": "Senior", "years_experience": "5+"}

Now the real posting:
Title: ''', title, '''
Description: ''', SUBSTR(description, 1, 6000)) AS prompt
    FROM `gc-job-intel.jobs_curated.build1_sample`
  ),
  STRUCT(0.0 AS temperature, 2048 AS max_output_tokens, TRUE AS flatten_json_output)
);

-- Query C: check the raw results (an empty status means success)
SELECT
  job_id,
  title,
  ml_generate_text_status AS status,
  ml_generate_text_llm_result AS raw_output
FROM `gc-job-intel.jobs_curated.build1_extractions`;

-- Query D: strip markdown fences, parse JSON once, read typed fields
-- (SAFE.JSON_VALUE_ARRAY is not supported, so SAFE.PARSE_JSON is applied once instead)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build1_parsed` AS
WITH cleaned AS (
  SELECT
    job_id,
    title,
    ml_generate_text_status AS status,
    REGEXP_REPLACE(ml_generate_text_llm_result,
                   r'^\s*```(?:json)?\s*|\s*```\s*$', '') AS json_text
  FROM `gc-job-intel.jobs_curated.build1_extractions`
),
parsed AS (
  SELECT *, SAFE.PARSE_JSON(json_text) AS j
  FROM cleaned
)
SELECT
  job_id,
  title,
  status,
  JSON_VALUE_ARRAY(j, '$.skills')      AS skills,
  JSON_VALUE(j, '$.seniority')         AS seniority,
  JSON_VALUE(j, '$.years_experience')  AS years_experience,
  j IS NULL                            AS parse_failed
FROM parsed;

SELECT job_id, title, skills, seniority, years_experience, status, parse_failed
FROM `gc-job-intel.jobs_curated.build1_parsed`
ORDER BY parse_failed DESC, job_id;

-- Query E: health check on all 20
SELECT
  COUNT(*)                                          AS total_rows,
  COUNTIF(IFNULL(status, '') != '')                 AS api_errors,
  COUNTIF(parse_failed)                             AS parse_failures,
  ROUND(AVG(ARRAY_LENGTH(skills)), 1)               AS avg_skills_per_posting,
  COUNTIF(seniority = 'Not found')                  AS seniority_not_found,
  COUNTIF(years_experience = 'Not found')           AS years_not_found
FROM `gc-job-intel.jobs_curated.build1_parsed`;

-- Query F: Gemini vs. the 39-skill regex dictionary, headline numbers
WITH g AS (
  SELECT DISTINCT job_id, LOWER(TRIM(s)) AS skill
  FROM `gc-job-intel.jobs_curated.build1_parsed`, UNNEST(skills) AS s
),
r AS (
  SELECT DISTINCT ps.job_id, LOWER(TRIM(ps.skill)) AS skill
  FROM `gc-job-intel.jobs_curated.posting_skills` ps
  JOIN `gc-job-intel.jobs_curated.build1_sample` USING (job_id)
),
both_methods AS (
  SELECT * FROM g INTERSECT DISTINCT SELECT * FROM r
)
SELECT
  (SELECT COUNT(*) FROM g)            AS gemini_skills_found,
  (SELECT COUNT(*) FROM r)            AS regex_skills_found,
  (SELECT COUNT(*) FROM both_methods) AS found_by_both;

-- Query G: what each method found that the other missed
WITH g AS (
  SELECT DISTINCT job_id, LOWER(TRIM(s)) AS skill
  FROM `gc-job-intel.jobs_curated.build1_parsed`, UNNEST(skills) AS s
),
r AS (
  SELECT DISTINCT ps.job_id, LOWER(TRIM(ps.skill)) AS skill
  FROM `gc-job-intel.jobs_curated.posting_skills` ps
  JOIN `gc-job-intel.jobs_curated.build1_sample` USING (job_id)
)
SELECT 'gemini_only' AS found_by, skill, COUNT(*) AS postings
FROM (SELECT * FROM g EXCEPT DISTINCT SELECT * FROM r)
GROUP BY skill
UNION ALL
SELECT 'regex_only', skill, COUNT(*)
FROM (SELECT * FROM r EXCEPT DISTINCT SELECT * FROM g)
GROUP BY skill
ORDER BY found_by, postings DESC;
