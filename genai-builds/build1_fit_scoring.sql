-- Build 1, Phase 3: explainable 1-10 fit score, resume vs. job postings (BigQuery editor)
-- The resume is fictional. Bias guard + anchored rubric + reason, matched and missing skills.
-- Result: right roles averaged 4.6 vs. 1.7 for wrong roles (2.7x); best real Data Analyst match 7/10.

-- Query H: score the resume against the 20 sample postings (wrong roles)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build1_scores` AS
SELECT *
FROM ML.GENERATE_TEXT(
  MODEL `gc-job-intel.jobs_curated.gemini_flash`,
  (
    SELECT
      s.job_id,
      s.title,
      CONCAT('''You are an objective hiring screener. Score how well the candidate fits the job.
Judge ONLY skills, experience and qualifications. Ignore name, age, gender, ethnicity, school prestige and employment gaps.

Scoring rubric:
9-10 = meets nearly all requirements; 7-8 = meets most, minor gaps;
4-6 = partial fit, important gaps; 1-3 = little or no fit.

Return ONLY valid JSON with exactly these keys:
- "score": integer 1-10
- "reason": one or two plain-English sentences a recruiter can read in 10 seconds
- "matched_skills": array of requirements the candidate clearly meets
- "missing_skills": array of key requirements the candidate lacks
Use only the resume and posting below. Never assume experience the resume does not state.

CANDIDATE RESUME:
Data Analyst, 3 years. SQL (daily, BigQuery and PostgreSQL), Python (pandas), Tableau and Excel dashboards,
A/B test analysis, stakeholder reporting. Previously 2 years in customer support, handling escalations
and training new hires. B.S. in Business Administration.

JOB POSTING:
Title: ''', s.title, '''
Description: ''', SUBSTR(s.description, 1, 6000)) AS prompt
    FROM `gc-job-intel.jobs_curated.build1_sample` s
  ),
  STRUCT(0.0 AS temperature, 1024 AS max_output_tokens, TRUE AS flatten_json_output)
);

-- Query I: parse and rank
WITH j AS (
  SELECT
    job_id, title, ml_generate_text_status AS status,
    SAFE.PARSE_JSON(REGEXP_REPLACE(ml_generate_text_llm_result,
      r'^\s*```(?:json)?\s*|\s*```\s*$', '')) AS out
  FROM `gc-job-intel.jobs_curated.build1_scores`
)
SELECT
  title,
  SAFE_CAST(JSON_VALUE(out, '$.score') AS INT64) AS score,
  JSON_VALUE(out, '$.reason')                    AS reason,
  JSON_VALUE_ARRAY(out, '$.matched_skills')      AS matched,
  JSON_VALUE_ARRAY(out, '$.missing_skills')      AS missing,
  status
FROM j
ORDER BY score DESC;

-- Query J: score the same resume against 5 real Data Analyst postings (right roles)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build1_scores_analyst` AS
SELECT *
FROM ML.GENERATE_TEXT(
  MODEL `gc-job-intel.jobs_curated.gemini_flash`,
  (
    SELECT
      job_id, title,
      CONCAT('''You are an objective hiring screener. Score how well the candidate fits the job.
Judge ONLY skills, experience and qualifications. Ignore name, age, gender, ethnicity, school prestige and employment gaps.

Scoring rubric:
9-10 = meets nearly all requirements; 7-8 = meets most, minor gaps;
4-6 = partial fit, important gaps; 1-3 = little or no fit.

Return ONLY valid JSON with exactly these keys:
- "score": integer 1-10
- "reason": one or two plain-English sentences a recruiter can read in 10 seconds
- "matched_skills": array of requirements the candidate clearly meets
- "missing_skills": array of key requirements the candidate lacks
Use only the resume and posting below. Never assume experience the resume does not state.

CANDIDATE RESUME:
Data Analyst, 3 years. SQL (daily, BigQuery and PostgreSQL), Python (pandas), Tableau and Excel dashboards,
A/B test analysis, stakeholder reporting. Previously 2 years in customer support, handling escalations
and training new hires. B.S. in Business Administration.

JOB POSTING:
Title: ''', title, '''
Description: ''', SUBSTR(description, 1, 6000)) AS prompt
    FROM `gc-job-intel.jobs_curated.postings`
    WHERE LOWER(title) LIKE '%data analyst%'
      AND description IS NOT NULL
    ORDER BY FARM_FINGERPRINT(CAST(job_id AS STRING))
    LIMIT 5
  ),
  STRUCT(0.0 AS temperature, 1024 AS max_output_tokens, TRUE AS flatten_json_output)
);

-- Scoreboard: wrong roles vs. right roles
WITH j AS (
  SELECT 'wrong roles (random 20)' AS test_set,
    SAFE.PARSE_JSON(REGEXP_REPLACE(ml_generate_text_llm_result, r'^\s*```(?:json)?\s*|\s*```\s*$', '')) AS out
  FROM `gc-job-intel.jobs_curated.build1_scores`
  UNION ALL
  SELECT 'right roles (data analyst)',
    SAFE.PARSE_JSON(REGEXP_REPLACE(ml_generate_text_llm_result, r'^\s*```(?:json)?\s*|\s*```\s*$', ''))
  FROM `gc-job-intel.jobs_curated.build1_scores_analyst`
)
SELECT
  test_set,
  COUNT(*) AS postings,
  ROUND(AVG(SAFE_CAST(JSON_VALUE(out, '$.score') AS INT64)), 1) AS avg_score,
  MIN(SAFE_CAST(JSON_VALUE(out, '$.score') AS INT64)) AS min_score,
  MAX(SAFE_CAST(JSON_VALUE(out, '$.score') AS INT64)) AS max_score
FROM j
GROUP BY test_set;

-- Reasons behind the lowest right-role scores (recruiter review)
SELECT
  title,
  SAFE_CAST(JSON_VALUE(out, '$.score') AS INT64) AS score,
  JSON_VALUE(out, '$.reason') AS reason,
  JSON_VALUE_ARRAY(out, '$.missing_skills') AS missing
FROM (
  SELECT title, SAFE.PARSE_JSON(REGEXP_REPLACE(ml_generate_text_llm_result,
    r'^\s*```(?:json)?\s*|\s*```\s*$', '')) AS out
  FROM `gc-job-intel.jobs_curated.build1_scores_analyst`
)
ORDER BY score;
