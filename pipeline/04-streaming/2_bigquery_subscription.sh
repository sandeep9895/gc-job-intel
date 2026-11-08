# BigQuery subscription
bq mk --table gc-job-intel:jobs_raw.postings_stream \
job_id:INTEGER,title:STRING,company_name:STRING,description:STRING,experience_level:STRING,work_type:STRING,is_remote:BOOLEAN,application_type:STRING,normalized_salary:FLOAT,sent_at:STRING

PROJECT_NUMBER=$(gcloud projects describe gc-job-intel --format="value(projectNumber)")
gcloud projects add-iam-policy-binding gc-job-intel \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor" --condition=None

gcloud pubsub subscriptions create new-postings-to-bq \
  --topic=new-postings \
  --bigquery-table=gc-job-intel:jobs_raw.postings_stream \
  --use-table-schema --drop-unknown-fields
