# Create, update and backfill the schedule (Cloud Shell)
gcloud services enable bigquerydatatransfer.googleapis.com

bq mk --transfer_config \
  --location=us-central1 \
  --data_source=scheduled_query \
  --display_name=daily_risk_snapshot \
  --schedule='every day 05:00' \
  --params='{"query":"INSERT INTO `gc-job-intel.jobs_curated.daily_risk_snapshot` SELECT @run_date AS snapshot_date, risk_tier, COUNT(*) AS postings FROM `gc-job-intel.jobs_curated.stream_scored` GROUP BY risk_tier"}'

# Idempotent version (current)
bq update --transfer_config \
  --params='{"query":"DELETE FROM `gc-job-intel.jobs_curated.daily_risk_snapshot` WHERE snapshot_date = @run_date; INSERT INTO `gc-job-intel.jobs_curated.daily_risk_snapshot` SELECT @run_date AS snapshot_date, risk_tier, COUNT(*) AS postings FROM `gc-job-intel.jobs_curated.stream_scored` GROUP BY risk_tier"}' \
  projects/${PROJECT_NUMBER}/locations/us-central1/transferConfigs/${TRANSFER_CONFIG_ID}

# Backfill / test a specific day
bq mk --transfer_run \
  --run_time='2026-11-04T11:45:00Z' \
  projects/${PROJECT_NUMBER}/locations/us-central1/transferConfigs/${TRANSFER_CONFIG_ID}

bq query --use_legacy_sql=false 'SELECT * FROM `gc-job-intel.jobs_curated.daily_risk_snapshot` ORDER BY risk_tier'
