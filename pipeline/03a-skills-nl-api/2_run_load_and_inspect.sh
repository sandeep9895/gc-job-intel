# Run, load and inspect
python3 extract.py
bq load --source_format=NEWLINE_DELIMITED_JSON --autodetect jobs_curated.job_entities entities.jsonl
wc -l entities.jsonl

bq query --use_legacy_sql=false '
SELECT entity_type, COUNT(*) AS entities, COUNT(DISTINCT entity) AS distinct_names
FROM `gc-job-intel.jobs_curated.job_entities`
GROUP BY entity_type ORDER BY entities DESC'

bq query --use_legacy_sql=false '
SELECT LOWER(entity) AS entity, entity_type,
       COUNT(DISTINCT job_id) AS postings, ROUND(AVG(salience), 3) AS avg_salience
FROM `gc-job-intel.jobs_curated.job_entities`
GROUP BY entity, entity_type ORDER BY postings DESC LIMIT 25'
