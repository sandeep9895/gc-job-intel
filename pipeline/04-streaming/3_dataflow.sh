# Dataflow
bq mk --table gc-job-intel:jobs_raw.postings_dataflow \
job_id:INTEGER,title:STRING,company_name:STRING,description:STRING,experience_level:STRING,work_type:STRING,is_remote:BOOLEAN,application_type:STRING,normalized_salary:FLOAT,sent_at:STRING
gcloud pubsub subscriptions create new-postings-dataflow --topic=new-postings

gcloud dataflow flex-template run postings-stream-$(date +%H%M) \
  --region=us-central1 \
  --template-file-gcs-location=gs://dataflow-templates-us-central1/latest/flex/PubSub_to_BigQuery_Flex \
  --max-workers=1 --worker-machine-type=e2-standard-2 \
  --parameters=inputSubscription=projects/gc-job-intel/subscriptions/new-postings-dataflow,outputTableSpec=gc-job-intel:jobs_raw.postings_dataflow

bq query --use_legacy_sql=false 'SELECT COUNT(*) AS row_count FROM `gc-job-intel.jobs_raw.postings_dataflow`'
gcloud dataflow jobs list --region=us-central1 --status=active
gcloud dataflow jobs drain JOB_ID --region=us-central1
