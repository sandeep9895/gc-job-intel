import json, time, datetime
from google.cloud import bigquery, pubsub_v1

PROJECT = "gc-job-intel"
bq = bigquery.Client(project=PROJECT)
publisher = pubsub_v1.PublisherClient()
topic = publisher.topic_path(PROJECT, "new-postings")

rows = bq.query("""
SELECT job_id, title, company_name, SUBSTR(description, 1, 5000) AS description,
       experience_level, work_type, is_remote, application_type, normalized_salary
FROM `gc-job-intel.jobs_curated.postings`
ORDER BY FARM_FINGERPRINT(CONCAT('sim', CAST(job_id AS STRING)))
LIMIT 100
""").result()

for i, r in enumerate(rows, 1):
    msg = dict(r)
    msg["sent_at"] = datetime.datetime.utcnow().isoformat() + "Z"
    publisher.publish(topic, json.dumps(msg, default=str).encode("utf-8")).result()
    print(f"{i}/100 sent: {msg['title'][:50]}")
    time.sleep(0.5)
