-- Build 2: Natural Language API vs. Gemini vs. regex for skill extraction (BigQuery editor)
-- Requires the nl_api remote model from 01_remote_models.sql.
-- Result: NL API returned 2,498 entities, only 3.2% of them skills; it contained 35% of Gemini's
-- 201 skills and 39% of the 66 regex skills. Verdict: Gemini for skill extraction.

-- 2a: call the NL API on the same 20 postings as Build 1
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build2_nl_raw` AS
SELECT *
FROM ML.UNDERSTAND_TEXT(
  MODEL `gc-job-intel.jobs_curated.nl_api`,
  (
    SELECT job_id, title,
           CONCAT(title, '. ', SUBSTR(description, 1, 6000)) AS text_content
    FROM `gc-job-intel.jobs_curated.build1_sample`
  ),
  STRUCT('analyze_entities' AS nlu_option)
);

-- 2b: flatten the entities into rows
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build2_nl_entities` AS
SELECT
  job_id,
  title,
  LOWER(TRIM(JSON_VALUE(e, '$.name')))              AS entity,
  JSON_VALUE(e, '$.type')                           AS entity_type,
  SAFE_CAST(JSON_VALUE(e, '$.salience') AS FLOAT64) AS salience
FROM `gc-job-intel.jobs_curated.build2_nl_raw`,
     UNNEST(JSON_QUERY_ARRAY(ml_understand_text_result, '$.entities')) AS e;

-- 2c: what did it find, by entity type?
SELECT
  entity_type,
  COUNT(*)                    AS entities,
  COUNT(DISTINCT job_id)      AS postings,
  ARRAY_AGG(entity ORDER BY salience DESC LIMIT 8) AS top_examples
FROM `gc-job-intel.jobs_curated.build2_nl_entities`
GROUP BY entity_type
ORDER BY entities DESC;

-- 3: three-way comparison (Gemini side uses hard + domain skills only)
WITH nl AS (
  SELECT DISTINCT job_id, entity AS skill
  FROM `gc-job-intel.jobs_curated.build2_nl_entities`
),
gem AS (
  SELECT DISTINCT job_id, LOWER(TRIM(s)) AS skill
  FROM `gc-job-intel.jobs_curated.build1_parsed_v2`,
       UNNEST(ARRAY_CONCAT(IFNULL(hard_skills, []), IFNULL(domain_skills, []))) AS s
),
rx AS (
  SELECT DISTINCT ps.job_id, LOWER(TRIM(ps.skill)) AS skill
  FROM `gc-job-intel.jobs_curated.posting_skills` ps
  JOIN `gc-job-intel.jobs_curated.build1_sample` USING (job_id)
),
known AS (SELECT * FROM gem UNION DISTINCT SELECT * FROM rx)
SELECT
  (SELECT COUNT(*) FROM nl)                                AS nl_entities,
  (SELECT COUNT(*) FROM gem)                               AS gemini_skills,
  (SELECT COUNT(*) FROM rx)                                AS regex_skills,
  (SELECT COUNT(*) FROM gem JOIN nl USING (job_id, skill)) AS gemini_skills_nl_also_found,
  (SELECT COUNT(*) FROM rx  JOIN nl USING (job_id, skill)) AS regex_skills_nl_also_found,
  ROUND(100 * (SELECT COUNT(*) FROM nl JOIN known USING (job_id, skill))
            / (SELECT COUNT(*) FROM nl), 1)                AS pct_nl_entities_that_are_skills;
