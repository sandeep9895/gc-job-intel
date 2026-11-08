#!/usr/bin/env bash
# Build 1, Phase 1: connect BigQuery to Gemini and the Natural Language API (run in Cloud Shell)

# Enable the APIs used by the remote models
gcloud services enable aiplatform.googleapis.com bigqueryconnection.googleapis.com language.googleapis.com \
  --project=gc-job-intel

# Create a Cloud Resource connection that BigQuery uses to call Vertex AI
bq mk --connection --location=us-central1 --project_id=gc-job-intel \
  --connection_type=CLOUD_RESOURCE gemini_conn

# Show the connection's service account (copy the serviceAccountId value)
bq show --connection gc-job-intel.us-central1.gemini_conn

# Replace with the serviceAccountId printed above, e.g. bqcx-<PROJECT_NUMBER>-xxxx@gcp-sa-bigquery-condel.iam.gserviceaccount.com
CONNECTION_SA="bqcx-${PROJECT_NUMBER}-xxxx@gcp-sa-bigquery-condel.iam.gserviceaccount.com"

# Gemini (generative model) needs Vertex AI User
gcloud projects add-iam-policy-binding gc-job-intel \
  --member="serviceAccount:${CONNECTION_SA}" \
  --role="roles/aiplatform.user"

# Pre-trained APIs such as the Natural Language API need Service Usage Consumer (Build 2)
gcloud projects add-iam-policy-binding gc-job-intel \
  --member="serviceAccount:${CONNECTION_SA}" \
  --role="roles/serviceusage.serviceUsageConsumer"
