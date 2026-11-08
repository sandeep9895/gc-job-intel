-- Build 3: resume name redaction for an anonymized Skills Focus Mode (BigQuery editor)
-- All resumes below are fictional. true_names and must_keep are the answer key.
-- Result: Gemini caught 9 of 9 names with 0 of 16 false positives;
--         NL API caught 8 of 9 (missed Linda Park) with 2 of 16 false positives.

-- Step 1: test set with traps (tools, companies and a famous name that look like people)
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build3_resumes` AS
SELECT * FROM UNNEST([
  STRUCT(1 AS resume_id,
    'Priya Ramanathan | priya.ramanathan@example.com | (216) 555-0141. DevOps Engineer, 5 years. Built CI/CD pipelines with Jenkins and GitHub Actions; scripted in Bash and Python. Previously at Johnson & Johnson. References: Mark Ellison, former manager.' AS resume_text,
    ['Priya Ramanathan', 'Mark Ellison'] AS true_names,
    ['Jenkins', 'Bash', 'Johnson & Johnson'] AS must_keep),
  STRUCT(2,
    'Oluwaseun Adeyemi, Backend Developer. 4 years with Ruby on Rails and Django; some Julia for data work. Mentored by Dr. Grace Liu. Contact: seun.adeyemi@example.com.',
    ['Oluwaseun Adeyemi', 'Grace Liu'],
    ['Ruby on Rails', 'Django', 'Julia']),
  STRUCT(3,
    'José García-López. Manufacturing Engineer at Ford Motor Company, 6 years. Lean Six Sigma Black Belt, AutoCAD, SolidWorks. Reports to Linda Park.',
    ['José García-López', 'Linda Park'],
    ['Ford Motor Company', 'AutoCAD', 'SolidWorks']),
  STRUCT(4,
    'Nguyen Thi Lan — Registered Nurse, 3 years ICU. BLS and ACLS certified. Charting in Epic. Worked with Dr. Ahmed Hassan at Cleveland Clinic.',
    ['Nguyen Thi Lan', 'Ahmed Hassan'],
    ['Epic', 'BLS', 'ACLS', 'Cleveland Clinic']),
  STRUCT(5,
    'Sam Walton Jr. Data Analyst. SQL, Tableau, Power BI, Excel (VLOOKUP, pivot tables). Analyzed sales for Walmart and Dell. LinkedIn: linkedin.com/in/samwaltonjr',
    ['Sam Walton Jr.'],
    ['Tableau', 'Power BI', 'Walmart', 'Dell'])
]);

-- Step 2a: NL API keeps PERSON entities with PROPER mentions
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build3_nl` AS
SELECT
  resume_id,
  ARRAY(
    SELECT DISTINCT JSON_VALUE(m, '$.text.content')
    FROM UNNEST(JSON_QUERY_ARRAY(ml_understand_text_result, '$.entities')) AS e,
         UNNEST(JSON_QUERY_ARRAY(e, '$.mentions')) AS m
    WHERE JSON_VALUE(e, '$.type') = 'PERSON'
      AND JSON_VALUE(m, '$.type') = 'PROPER'
  ) AS nl_names
FROM ML.UNDERSTAND_TEXT(
  MODEL `gc-job-intel.jobs_curated.nl_api`,
  (SELECT resume_id, resume_text AS text_content
   FROM `gc-job-intel.jobs_curated.build3_resumes`),
  STRUCT('analyze_entities' AS nlu_option)
);

-- Step 2b: Gemini with explicit do-not-redact rules returns names and redacted text
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.build3_gemini_raw` AS
SELECT *
FROM ML.GENERATE_TEXT(
  MODEL `gc-job-intel.jobs_curated.gemini_flash`,
  (
    SELECT resume_id, CONCAT('''You redact resumes for bias-free screening.
Find every personal name of a real person in the text: the candidate, references, managers, mentors and colleagues.
Do NOT treat these as names: software, tools and programming languages (e.g. Jenkins, Ruby, Julia, Django, Bash),
companies and employers (e.g. Johnson & Johnson, Ford Motor Company, Dell), hospitals and institutions, certifications.

Return ONLY valid JSON with exactly these keys:
- "names": array of each personal name exactly as written
- "redacted_text": the full text with each personal name replaced by [NAME], each email by [EMAIL], each phone number by [PHONE] and each profile URL by [URL]

RESUME:
''', resume_text) AS prompt
    FROM `gc-job-intel.jobs_curated.build3_resumes`
  ),
  STRUCT(0.0 AS temperature, 2048 AS max_output_tokens, TRUE AS flatten_json_output)
);

-- Quick look before scoring
SELECT
  r.resume_id,
  n.nl_names,
  JSON_VALUE_ARRAY(g.j, '$.names')    AS gemini_names,
  JSON_VALUE(g.j, '$.redacted_text')  AS gemini_redacted
FROM `gc-job-intel.jobs_curated.build3_resumes` r
JOIN `gc-job-intel.jobs_curated.build3_nl` n USING (resume_id)
JOIN (
  SELECT resume_id,
         SAFE.PARSE_JSON(REGEXP_REPLACE(ml_generate_text_llm_result,
           r'^\s*```(?:json)?\s*|\s*```\s*$', '')) AS j
  FROM `gc-job-intel.jobs_curated.build3_gemini_raw`
) g USING (resume_id)
ORDER BY resume_id;

-- Step 3: automatic scoring against the answer key.
-- BigQuery rejects NOT EXISTS with a STRPOS condition (anti-join on a non-equality),
-- so every (expected, detected) pair is built with UNNEST and aggregated with LOGICAL_OR.
WITH g AS (
  SELECT resume_id,
         SAFE.PARSE_JSON(REGEXP_REPLACE(ml_generate_text_llm_result,
           r'^\s*```(?:json)?\s*|\s*```\s*$', '')) AS j
  FROM `gc-job-intel.jobs_curated.build3_gemini_raw`
),
d AS (
  SELECT r.resume_id, r.true_names, r.must_keep, 'NL API' AS tool, n.nl_names AS detected
  FROM `gc-job-intel.jobs_curated.build3_resumes` r
  JOIN `gc-job-intel.jobs_curated.build3_nl` n USING (resume_id)
  UNION ALL
  SELECT r.resume_id, r.true_names, r.must_keep, 'Gemini', JSON_VALUE_ARRAY(g.j, '$.names')
  FROM `gc-job-intel.jobs_curated.build3_resumes` r
  JOIN g USING (resume_id)
),
names AS (
  SELECT d.tool, d.resume_id, t AS name,
         IFNULL(LOGICAL_OR(STRPOS(LOWER(x), LOWER(t)) > 0 OR STRPOS(LOWER(t), LOWER(x)) > 0), FALSE) AS caught
  FROM d, UNNEST(d.true_names) AS t
  LEFT JOIN UNNEST(d.detected) AS x ON TRUE
  GROUP BY 1, 2, 3
),
keeps AS (
  SELECT d.tool, d.resume_id, k AS term,
         IFNULL(LOGICAL_OR(STRPOS(LOWER(x), LOWER(k)) > 0 OR STRPOS(LOWER(k), LOWER(x)) > 0), FALSE) AS removed
  FROM d, UNNEST(d.must_keep) AS k
  LEFT JOIN UNNEST(d.detected) AS x ON TRUE
  GROUP BY 1, 2, 3
),
n AS (
  SELECT tool,
         COUNTIF(caught) AS names_caught,
         COUNT(*)        AS names_total,
         ARRAY_AGG(IF(caught, NULL, name) IGNORE NULLS) AS all_missed
  FROM names GROUP BY tool
),
k AS (
  SELECT tool,
         COUNTIF(removed) AS wrongly_removed,
         COUNT(*)         AS must_keep_total,
         ARRAY_AGG(IF(removed, term, NULL) IGNORE NULLS) AS all_wrongly_removed
  FROM keeps GROUP BY tool
)
SELECT * FROM n JOIN k USING (tool);
