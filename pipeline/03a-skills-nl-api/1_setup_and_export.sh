# Setup and sample export
mkdir -p ~/skills && cd ~/skills
pip install --user --quiet google-cloud-language

bq query --use_legacy_sql=false --format=json --max_rows=50 '
SELECT job_id, title, SUBSTR(description, 1, 3000) AS description
FROM `gc-job-intel.jobs_curated.postings`
WHERE description IS NOT NULL
ORDER BY FARM_FINGERPRINT(CAST(job_id AS STRING))
LIMIT 50' > sample.json
