#!/usr/bin/env bash
# gc-job-intel: project setup, data lake and raw load (run in Cloud Shell)

# Set project and region
gcloud config set project gc-job-intel
gcloud config set compute/region us-central1

# Enable APIs and verify
gcloud services enable \
  bigquery.googleapis.com \
  storage.googleapis.com \
  pubsub.googleapis.com \
  dataflow.googleapis.com \
  language.googleapis.com \
  aiplatform.googleapis.com

gcloud services list --enabled | grep -E "bigquery|storage|pubsub|dataflow|language|aiplatform|compute"

# Create the lake bucket and warehouse datasets
gcloud storage buckets create gs://gc-job-intel-lake \
  --location=us-central1 \
  --uniform-bucket-level-access

bq --location=us-central1 mk --dataset \
  --description "Raw job postings, loaded as-is" \
  gc-job-intel:jobs_raw

bq --location=us-central1 mk --dataset \
  --description "Cleaned and modeled job data" \
  gc-job-intel:jobs_curated

gcloud storage buckets list --format="value(name,location)"
bq ls

# Verify uploaded files
gcloud storage ls -r "gs://gc-job-intel-lake/raw/**" | head -30
gcloud storage du -s -r gs://gc-job-intel-lake/raw/

# Load postings into BigQuery and inspect the schema
bq load \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  --allow_quoted_newlines \
  --max_bad_records=100 \
  jobs_raw.postings \
  "gs://gc-job-intel-lake/raw/source=linkedin_kaggle/ingest_date=2026-11-01/postings.csv"

bq show jobs_raw.postings
