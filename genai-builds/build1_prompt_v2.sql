-- Build 1, prompt v2: split skills into hard, domain and soft buckets (BigQuery editor)
-- Result: coverage of the 66 regex tags rose from 20 (30%) with v1 to 34 (52%) with v2.
-- Product decision: matching and screening use hard + domain skills only; soft skills are context.

-- Query K: rerun the extraction with v2
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build1_extractions_v2` AS
SELECT *
FROM ML.GENERATE_TEXT(
  MODEL `gc-job-intel.jobs_curated.gemini_flash`,
  (
    SELECT
      job_id, title,
      CONCAT('''You extract structured data from job postings.
Return ONLY valid JSON with exactly these keys:
- "hard_skills": tools, software, technologies, certifications and licenses (e.g. "SQL", "Salesforce", "CPR certification")
- "domain_skills": job-specific professional abilities that are not tools (e.g. "budgeting", "customer service", "patient assessment", "contract negotiation")
- "soft_skills": interpersonal or general traits (e.g. "communication", "teamwork", "problem solving")
- "seniority": one of "Intern", "Entry", "Mid", "Senior", "Lead", "Manager", "Director+", "Not found"
- "years_experience": minimum years required as written (e.g. "3+", "2-4"), or "Not found"
Each skill list: up to 10 items, short common names, only skills the posting actually requires or prefers.
Use only information in the posting. Never guess.

Example posting:
Title: Senior Data Engineer
Description: 5+ years building pipelines in Python and SQL. Airflow and AWS required. Must manage vendor budgets and communicate clearly with stakeholders.
Example output:
{"hard_skills": ["Python", "SQL", "Airflow", "AWS"], "domain_skills": ["data pipeline design", "budgeting"], "soft_skills": ["communication"], "seniority": "Senior", "years_experience": "5+"}

Now the real posting:
Title: ''', title, '''
Description: ''', SUBSTR(description, 1, 6000)) AS prompt
    FROM `gc-job-intel.jobs_curated.build1_sample`
  ),
  STRUCT(0.0 AS temperature, 2048 AS max_output_tokens, TRUE AS flatten_json_output)
);

-- Query L: parse it
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build1_parsed_v2` AS
WITH p AS (
  SELECT job_id, title, ml_generate_text_status AS status,
    SAFE.PARSE_JSON(REGEXP_REPLACE(ml_generate_text_llm_result,
      r'^\s*```(?:json)?\s*|\s*```\s*$', '')) AS j
  FROM `gc-job-intel.jobs_curated.build1_extractions_v2`
)
SELECT
  job_id, title, status,
  JSON_VALUE_ARRAY(j, '$.hard_skills')   AS hard_skills,
  JSON_VALUE_ARRAY(j, '$.domain_skills') AS domain_skills,
  JSON_VALUE_ARRAY(j, '$.soft_skills')   AS soft_skills,
  JSON_VALUE(j, '$.seniority')           AS seniority,
  JSON_VALUE(j, '$.years_experience')    AS years_experience,
  j IS NULL                              AS parse_failed
FROM p;

-- Query M: did v2 close the gap against the regex tags?
WITH g AS (
  SELECT DISTINCT job_id, LOWER(TRIM(s)) AS skill
  FROM `gc-job-intel.jobs_curated.build1_parsed_v2`,
       UNNEST(ARRAY_CONCAT(IFNULL(hard_skills, []), IFNULL(domain_skills, []), IFNULL(soft_skills, []))) AS s
),
r AS (
  SELECT DISTINCT ps.job_id, LOWER(TRIM(ps.skill)) AS skill, ps.category
  FROM `gc-job-intel.jobs_curated.posting_skills` ps
  JOIN `gc-job-intel.jobs_curated.build1_sample` USING (job_id)
)
SELECT
  COUNT(*) AS regex_tags,
  COUNTIF(g.skill IS NOT NULL) AS also_found_by_v2,
  ROUND(100 * COUNTIF(g.skill IS NOT NULL) / COUNT(*), 0) AS pct_covered
FROM r LEFT JOIN g USING (job_id, skill);
