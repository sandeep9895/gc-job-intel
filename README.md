# gc-job-intel

A job-market intelligence platform on Google Cloud, built on 123,849 real LinkedIn job postings. It finds **ghost jobs** (postings that stay open long after hiring has stopped), extracts skills with Gemini, and prototypes explainable, bias-aware candidate screening for [Get Connected AI](https://getconnectedai.com).

Built by Sandeep Joseph Eruva in November 2026 while working through Google Cloud's data engineering and AI/ML coursework, learning by building one real project instead of isolated labs.

## Highlights

| Area | Result |
| --- | --- |
| Ghost-job model | BigQuery ML logistic regression with class weights and leak-free features, **ROC AUC 0.90**. The riskiest ~3% of postings hold ~58% of stale listings. |
| Posting age | Apply rate falls from 19.8% (same day) to 6.2% (8–30 days open). |
| Streaming | Pub/Sub → BigQuery subscription → real-time scoring view, plus a Dataflow job. |
| Gemini skill extraction | Runs entirely in BigQuery SQL. 0 API errors, 0 parse failures; 201 hard and domain skills across 20 postings vs. 66 from a regex dictionary. |
| Explainable fit scoring | Anchored 1–10 rubric with a bias guard. Right-role postings averaged 4.6 vs. 1.7 for wrong roles (2.7x). |
| Name redaction | Gemini removed 9 of 9 names with 0 of 16 false positives; the Natural Language API caught 8 of 9 with 2 false positives. |

The GenAI test sets are small (20 postings, 5 fictional resumes), so treat those numbers as prototype evidence, not benchmarks.

## Architecture

```
Kaggle CSVs ──► Cloud Storage lake ──► BigQuery jobs_raw ──► jobs_curated ──► BigQuery ML ghost-job model
                                                                  │                     │
                                     Pub/Sub ──► stream table ──► stream_scored view ◄──┘
                                                                  │
                         Nightly scheduled query ──► daily_risk_snapshot
                         Dataproc Serverless (PySpark) ──► skill co-occurrence
                         Gemini + NL API remote models ──► skills, fit scores, redaction
                         Looker Studio dashboard
```

## Repository layout

| Path | What's in it |
| --- | --- |
| `pipeline/01-setup` | Project, APIs, lake bucket, datasets, raw load (Cloud Shell) |
| `pipeline/02-warehouse-and-model` | Curated layer, company features, ghost-job training, evaluation, scoring, dashboard table (queries 01–13) |
| `pipeline/03a-skills-nl-api` | First skill-extraction attempt with the Natural Language API |
| `pipeline/03b-skills-dictionary` | 39-skill SQL dictionary and skill analysis (queries 14–17) |
| `pipeline/04-streaming` | Pub/Sub, BigQuery subscription, job-board simulator, Dataflow, real-time scoring view |
| `pipeline/05-scheduled-pipeline` | Idempotent nightly snapshot (delete-then-insert) and backfill |
| `pipeline/06-spark-dataproc` | PySpark skill co-occurrence on Dataproc Serverless |
| `genai-builds/` | Gemini and NL API remote models; Builds 1–3 SQL; Build 4 AutoML vs. BigQuery ML write-up |
| `docs/` | Full learning report and study notes |

## How to run

1. Create a Google Cloud project and set `PROJECT_NUMBER` where scripts reference it.
2. Download the [LinkedIn Job Postings 2023–2024](https://www.kaggle.com/datasets/arshkon/linkedin-job-postings) dataset from Kaggle. The data isn't included in this repo.
3. Run `pipeline/01-setup/setup.sh` in Cloud Shell, then the SQL files in each folder in numeric order in the BigQuery editor.
4. For the GenAI builds, run `genai-builds/00_setup_gemini_connection.sh`, then `01_remote_models.sql`, then the build files.

Files ending in `.sh` run in Cloud Shell; `.sql` files run in the BigQuery editor. Small Gemini and NL API runs cost cents or fit in the free tier, but check current pricing first. Don't train AutoML in your own project; tabular training bills per node-hour.

## Docs

- [Learning report](docs/learning-report.md): every step, finding, gotcha and command for the pipeline
- [Intro to AI & ML on Google Cloud study guide](docs/intro-ai-ml-google-cloud-study-guide.md): course notes, lab log and the Build 1–4 log
- [GCP Data Engineering study guide](docs/gcp-data-engineering-study-guide.md): notes for the four-course specialization
- [Kaggle SQL notes](docs/kaggle-sql-notes.md): Intro to SQL and Advanced SQL exercises in BigQuery SQL

Course notes are my own summaries written from public syllabus pages, not copies of course material.
