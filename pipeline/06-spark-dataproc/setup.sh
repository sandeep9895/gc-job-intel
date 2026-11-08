# Setup
cd ~/skills
gcloud services enable dataproc.googleapis.com
gcloud compute networks subnets update default --region=us-central1 --enable-private-ip-google-access

PROJECT_NUMBER=$(gcloud projects describe gc-job-intel --format="value(projectNumber)")
gcloud projects add-iam-policy-binding gc-job-intel \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/dataproc.worker" --condition=None
