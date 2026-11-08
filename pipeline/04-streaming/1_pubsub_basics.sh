# Pub/Sub basics
gcloud pubsub topics create new-postings
gcloud pubsub subscriptions create new-postings-debug --topic=new-postings
gcloud pubsub topics publish new-postings --message='{"job_id": 1, "title": "Test Data Engineer", "company_name": "Get Connected AI"}'
gcloud pubsub subscriptions pull new-postings-debug --auto-ack --limit=5
