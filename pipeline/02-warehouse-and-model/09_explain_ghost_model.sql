-- 09 – Feature importance (`09_explain_ghost_model`)
SELECT *
FROM ML.GLOBAL_EXPLAIN(MODEL `gc-job-intel.jobs_curated.ghost_model_v1`)
ORDER BY attribution DESC;
