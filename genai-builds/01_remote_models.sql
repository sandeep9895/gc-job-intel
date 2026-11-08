-- Remote models on the gemini_conn connection (BigQuery editor)

-- Generative model: Gemini Flash
CREATE OR REPLACE MODEL `gc-job-intel.jobs_curated.gemini_flash`
  REMOTE WITH CONNECTION `gc-job-intel.us-central1.gemini_conn`
  OPTIONS (ENDPOINT = 'gemini-3.8-flash');

-- Smoke test: Gemini answers from SQL
SELECT ml_generate_text_llm_result AS reply
FROM ML.GENERATE_TEXT(
  MODEL `gc-job-intel.jobs_curated.gemini_flash`,
  (SELECT 'In one sentence, what does a technical recruiter do?' AS prompt),
  STRUCT(0.0 AS temperature, 256 AS max_output_tokens, TRUE AS flatten_json_output)
);

-- Pre-trained model: Cloud Natural Language API (Build 2)
CREATE OR REPLACE MODEL `gc-job-intel.jobs_curated.nl_api`
  REMOTE WITH CONNECTION `gc-job-intel.us-central1.gemini_conn`
  OPTIONS (REMOTE_SERVICE_TYPE = 'CLOUD_AI_NATURAL_LANGUAGE_V1');

-- Smoke test: the input column must be named text_content
SELECT ml_understand_text_status AS status, ml_understand_text_result AS result
FROM ML.UNDERSTAND_TEXT(
  MODEL `gc-job-intel.jobs_curated.nl_api`,
  (SELECT 'Joanne Rowling, who writes under the pen name Robert Galbraith, wrote the Harry Potter series.' AS text_content),
  STRUCT('analyze_entities' AS nlu_option)
);
