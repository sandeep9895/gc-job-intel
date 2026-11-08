# Submit and query
gcloud dataproc batches submit pyspark skill_pairs.py \
  --region=us-central1 \
  --batch=skill-pairs-$(date +%H%M) \
  --version=2.2 \
  --deps-bucket=gs://gc-job-intel-lake
