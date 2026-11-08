-- 08 – Train the model (`08_train_ghost_model_v1`)
CREATE OR REPLACE MODEL `gc-job-intel.jobs_curated.ghost_model_v1`
OPTIONS (
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['is_stale'],
  auto_class_weights = TRUE,
  data_split_method = 'RANDOM',
  data_split_eval_fraction = 0.2,
  enable_global_explain = TRUE
) AS
SELECT * EXCEPT (job_id, company_name)
FROM `gc-job-intel.jobs_curated.ghost_training`;
