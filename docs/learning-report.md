# gc-job-intel Learning Report

Nov 1, 2026 · @Sunny

**All four courses of *Data Engineering, Big Data, and Machine Learning on GCP* were covered in practice by Nov 5, three days before the Nov 8 target, by building one project on 123,849 real job postings.** The pipeline runs end to end: a Cloud Storage lake, raw and curated BigQuery layers, a nightly idempotent scheduled snapshot, real-time Pub/Sub streaming with Dataflow, a BigQuery ML ghost-job model (ROC AUC 0.90) scoring postings live, skill extraction, Spark on Dataproc, and a Data Studio dashboard.

**Pitch-ready findings:** the riskiest \~3% of postings hold \~58% of stale listings; apply rate falls from 20% to 6% as postings age; ML, Tableau, Agile and AWS postings are 2–3× more often stale.

## Summary

In session 1 (Nov 1) we built the storage and transformation layers of a job-market intelligence pipeline on Google Cloud; in session 2 (Nov 2) we added a ghost-job model and a dashboard. The first ghost-job feature is validated: **apply rate falls from 19.8% to 6.2% as a posting ages.**

This is a project-first way of learning the Coursera specialization *Data Engineering, Big Data, and Machine Learning on GCP*. Session 1 covered the practical core of Course 1 (data lakes and warehouses) and Course 2 (batch pipelines).

**Built so far**

- A GCP project (`gc-job-intel`) with a $25 budget alert and 7 APIs enabled
- A data lake in Cloud Storage with Hive-style folders
- 123,849 LinkedIn job postings loaded into BigQuery (raw layer)
- A curated table with fixed types, ghost-job features, dedupe, partitioning and clustering
- A company-level feature table

**Headline findings**

- 62.4% of postings are "reposted", but over 75% of those are refreshed the same day, so the raw repost flag is noise.
- Only about 2% of postings stay open longer than 7 days, so the ML problem is heavily imbalanced.
- Apply rate drops as postings age (19.8% same day vs 6.2% at 8–30 days): the first validated feature.
- A few large companies have 78–96% of postings open long, which looks like systematic evergreen or bulk reposting.

**Session 2 headlines**

- A BigQuery ML logistic regression ranks stale postings with ROC AUC 0.90.
- The riskiest \~3% of postings (High + Medium tiers) contain \~58% of all stale postings; High is 53% stale vs the 1.79% base rate.
- The company feature dominates, so big repeat posters get every posting flagged: the main v2 fix.
- A Data Studio dashboard shows the headline numbers, both findings and a company table, with three filters.

**Session 3 headlines**

- The dashboard is finished, renamed and filter-tested.
- The Natural Language API returned mostly generic words (67% type OTHER), so a 39-skill SQL dictionary now tags all 123,849 postings.
- Top skills: communication 28%, leadership 24%, sales 23%, customer service 21%.
- Machine learning, Tableau, Agile and AWS postings are 2–3× more often stale, though they also get higher apply rates.

**Streaming (session 3, Course 3)**

- Postings stream simulator → Pub/Sub → BigQuery in seconds, and a view scores each one with the model in real time.
- Live tier shares (1% / 1% / 98%) match history, so there's no training/serving skew.
- Duplicates from at-least-once delivery are removed in the view; the raw table keeps everything.
- A Dataflow job delivered all 100 test postings and was drained, so nothing is left running.

| Course | Status |
| --- | --- |
| 1. Data Lakes & Warehouses | Done |
| 2. Batch Pipelines | Done (scheduling in session 4, Dataproc / Spark in session 5) |
| 3. Streaming Pipelines | Done |
| 4. Smart Analytics, ML & AI | Done |

## Architecture

&#91;embedded content: gc-job-intel pipeline · 5 built stages, 1 planned\]

Data moves left to right across the top, then down into the curated layer; the model (built in session 2) scores every posting, and its results feed the Data Studio dashboard through \`dashboard\_postings\`.

## Resource inventory

Everything lives in one project in **us-central1 (Iowa)**, so storage and queries stay in one region.

| Resource | Name / value | Notes |
| --- | --- | --- |
| Project | `gc-job-intel` (project number redacted) | No organization; separate from the Get Connected AI Outreach project |
| Billing account | My Billing Account | Paid account since Oct 16, 2026 (no free-trial credits) |
| Budget | `gc-job-intel-budget` | $25/month, scoped to this project; email alerts at 50%, 90%, 100% |
| Default region | `us-central1` | Set in Cloud Shell with `gcloud config` |
| APIs enabled | BigQuery, Cloud Storage, Pub/Sub, Dataflow, Natural Language, Vertex AI, Compute Engine | Compute Engine was enabled when setting the default region |
| Bucket (data lake) | `gs://gc-job-intel-lake` | us-central1, Standard class, uniform bucket-level access, not public |
| Raw data path | `raw/source=linkedin_kaggle/ingest_date=2026-11-01/` | `postings.csv` (516.8 MB) plus `companies/`, `jobs/`, `mappings/` |
| Dataset | `jobs_raw` | Raw tables, loaded as-is |
| Dataset | `jobs_curated` | Cleaned, modeled tables |
| Table | `jobs_raw.postings` | 123,849 rows, 31 columns, about 515 MB |
| Table | `jobs_curated.postings` | 123,849 rows; partitioned by `listed_date`, clustered by `company_name`, `experience_level` |
| Table | `jobs_curated.company_features` | One row per company |
| Saved queries | `03_apply_rate_by_age`, `04_create_curated_postings`, `06_create_company_features` | Saved in BigQuery with version history (personal space) |

**Added in session 2**

| Resource | Name / value | Notes |
| --- | --- | --- |
| Table | `jobs_curated.ghost_training` | Label + leak-free features, 123,849 rows |
| Model | `jobs_curated.ghost_model_v1` | Logistic regression, class-weighted |
| Table | `jobs_curated.posting_scores` | Stale score and risk tier per posting |
| Table | `jobs_curated.dashboard_postings` | Lean table feeding the dashboard |
| Dashboard | Data Studio report (to be renamed *Get Connected - Job Market Intelligence*) | Embedded BigQuery data source |
| Saved queries | `07_create_ghost_training`, `08_train_ghost_model_v1`, `09_explain_ghost_model`, `10_threshold_analysis`, `11_score_postings`, `12_tier_performance`, `13_create_dashboard_table` | Some may still need saving |

**Added in session 3**

| Resource | Name / value | Notes |
| --- | --- | --- |
| Cloud Shell folder | `~/skills` | `sample.json`, `extract.py`, `entities.jsonl` |
| Table | `jobs_curated.job_entities` | 5,225 Natural Language API entities from 50 postings |
| Table | `jobs_curated.skill_dictionary` | 39 skills with regex patterns and categories |
| Table | `jobs_curated.posting_skills` | One row per posting × matched skill |
| Dashboard | [Get Connected - Job Market Intelligence](https://datastudio.google.com/u/0/reporting/89a08fb7-d0ec-4893-a707-fa13c5baea76/page/HejCG) | Renamed and finished |
| Saved queries | `14_create_skill_dictionary`, `15_create_posting_skills`, `16_top_skills`, `17_skills_vs_stale` |  |

**Added for streaming**

| Resource | Name / value | Notes |
| --- | --- | --- |
| Pub/Sub topic | `new-postings` | Receives new-posting events |
| Subscription | `new-postings-debug` | Pull, for testing |
| Subscription | `new-postings-to-bq` | BigQuery subscription → `postings_stream` |
| Subscription | `new-postings-dataflow` | Read by the Dataflow job |
| Table | `jobs_raw.postings_stream` | Streamed postings (201 raw rows incl. duplicates) |
| Table | `jobs_raw.postings_dataflow` | 100 rows written by Dataflow |
| View | `jobs_curated.stream_scored` | Deduped, real-time risk scores |
| Dataflow job | `postings-stream-1653` | Drained; no longer billing |
| IAM | Pub/Sub service account → BigQuery Data Editor | Needed for the BigQuery subscription |
| Cloud Shell | `~/skills/simulate.py` | Job board simulator |
| Saved queries | `18_create_stream_scored`, `19_stream_tier_counts`, `20_stream_top_risky` |  |

**Added for scheduling (session 4)**

| Resource | Name / value | Notes |
| --- | --- | --- |
| API | BigQuery Data Transfer | Runs scheduled queries |
| Table | `jobs_curated.daily_risk_snapshot` | One dated row per tier per day |
| Scheduled query | `daily_risk_snapshot` (us-central1, config `6af7f86e-0000-2271-a96b-2405886f8d14`) | Every day 05:00 UTC; delete-then-insert |
| To delete | Old `daily_risk_snapshot` in location US | Failed; superseded |

## Step 1: GCP setup

We created a dedicated project, put a spending alert on it, and switched on the services the pipeline needs.

1. **Created project `gc-job-intel`** under the existing billing account, with "No organization". We kept it separate from the existing *Get Connected AI Outreach* project so experiments can't affect outreach work, costs show per project, and the whole thing can be deleted in one step.
2. **Set a $25 monthly budget** scoped only to this project, with alerts at 50%, 90% and 100%. The account is already paid, so this alert is the main cost guardrail.
3. **Opened Cloud Shell**, a free browser-based Linux machine with `gcloud` and `bq` pre-installed and authenticated.
4. **Set the default project and region** (`us-central1`). `gcloud` asked to enable the Compute Engine API; we said yes because Dataflow runs on Compute Engine VMs.
5. **Enabled 6 more APIs** in one command: BigQuery, Cloud Storage, Pub/Sub, Dataflow, Natural Language and Vertex AI, then verified with `gcloud services list`.

**Concepts learned**

- **Project** = the container for resources, permissions and billing; its ID is global and permanent.
- **Billing account** pays for one or more projects.
- **Organization** = the top of the hierarchy (organization → folders → projects); only matters for company-managed accounts.
- **APIs are off by default.** You enable each service before use; enabling costs nothing.
- **Budgets alert but don't cap.** Optional spending caps can stop spending; alerts only email.
- **Regions** decide where data and compute physically live; keeping everything in one region avoids cross-region issues.

## Step 2: Data lake and raw load

The raw Kaggle files now sit untouched in Cloud Storage, and `postings.csv` is loaded into BigQuery as `jobs_raw.postings` (123,849 rows, none dropped).

**Data source.** [LinkedIn Job Postings (2023 – 2024)](https://www.kaggle.com/datasets/arshkon/linkedin-job-postings) by Arsh Koneru on Kaggle: about 124,000 postings, 31 columns, plus company, skill, industry and benefit files. It was scraped from LinkedIn, so it is for learning and pipeline-building only, not for use inside the Get Connected product. Its license is still to be checked on the Kaggle page.

1. **Created the bucket** `gs://gc-job-intel-lake` in us-central1 with uniform bucket-level access.
2. **Created two BigQuery datasets**: `jobs_raw` (as loaded) and `jobs_curated` (cleaned and modeled).
3. **Downloaded the Kaggle zip**, extracted it, and uploaded `postings.csv` plus the `companies`, `jobs` and `mappings` folders through the console.
4. **Used a Hive-style path:** `raw/source=linkedin_kaggle/ingest_date=2026-11-01/`. The path records where the data came from and when it arrived, and later loads go into new date folders instead of overwriting.
5. **Loaded `postings.csv`** with `bq load` using `--autodetect`, `--allow_quoted_newlines` and `--max_bad_records=100`. The load took 65 seconds.

**Concepts learned**

- **Data lake vs warehouse.** The lake (Cloud Storage) keeps original files cheaply and lets you reprocess them; the warehouse (BigQuery) holds queryable tables.
- **Layers.** Raw = loaded as-is; curated = cleaned and modeled. Mistakes in cleaning never corrupt the source.
- **Paths are case-sensitive.** `Raw/` and `raw/` are different folders, so stick to lowercase.
- **Batch loads into BigQuery are free.** You pay only for storage and queries.
- **Autodetect is a guess.** It typed the Unix-millisecond timestamps as `FLOAT`; fixing types belongs in the curated layer.

## Step 3: Curated layer

One SQL statement turned the raw table into `jobs_curated.postings`: readable timestamps, ghost-job features, one row per job, and a storage layout that makes queries cheaper. A second statement built `jobs_curated.company_features`, one row per company.

**What the curated postings table does**

| Transformation | How | Why |
| --- | --- | --- |
| Fix types | `TIMESTAMP_MILLIS(CAST(x AS INT64))` on `listed_time`, `original_listed_time`, `expiry`, `closed_time` | Raw values were Unix milliseconds stored as floats |
| Clean text | `TRIM()` on company name and title | Stray spaces break grouping |
| Rename | `formatted_work_type` → `work_type`, `formatted_experience_level` → `experience_level` | Shorter, consistent names |
| Booleans | `IFNULL(remote_allowed, 0) = 1 AS is_remote` | Missing means not remote |
| Feature: `is_reposted` | `listed_time > original_listed_time` | First ghost-job signal |
| Feature: `days_open` | `TIMESTAMP_DIFF(listed_at, original_listed_at, DAY)` | How long the job has really been open |
| Audit column | `CURRENT_TIMESTAMP() AS _loaded_at` | Records when the row was built |
| Dedupe | `QUALIFY ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY listed_time DESC) = 1` | Keeps the latest row per job (none removed this time) |
| Partition | `PARTITION BY listed_date` | Date filters scan only matching days |
| Cluster | `CLUSTER BY company_name, experience_level` | Company and level filters scan less |

**Company features** (`jobs_curated.company_features`) per company: total postings, long-open postings (`days_open > 7`), % long-open, average and max days open, postings with apply data, apply rate (counting views only from postings that have apply data), and average views.

**Concepts learned**

- **Grain** = what one row represents. `postings` is one row per job; `company_features` is one row per company.
- **Partitioning and clustering** reduce bytes scanned, and so cost: the curated check query read 1.06 MB.
- **Dedupe defensively.** It removed nothing here, but future incremental loads will contain duplicates.
- **Rebuilding costs a full scan.** Recreating the curated table reads about 464 MB because it copies `description`.

## Step 4: Findings

The strongest signal so far is apply rate by posting age; the naive repost flag turned out to be noise.

**1. Profile of the data**

- 123,849 postings from 24,428 companies.
- `listed_time` spans only Mar 24 – Apr 20, 2024 (a 4-week scrape), but `original_listed_time` goes back to Dec 5, 2023, so real posting age can still be measured.
- 100,529 postings (81%) have no `applies` value, so any apply-based feature must use only the 19% that do.
- Average views 14.6, average applies 10.6.

**2. Reposting is mostly same-day refreshing**

77,237 postings (62.4%) have `listed_time > original_listed_time`, but the `days_open` quartiles are all 0 (max 135).

| Days open | Postings | Share | Avg views | Avg applies |
| --- | --- | --- | --- | --- |
| Same day | 113,185 | 91.4% | 14.9 | 10.8 |
| 1–7 days | 8,442 | 6.8% | 7.8 | 4.0 |
| 8–30 days | 2,192 | 1.8% | 24.3 | 7.8 |
| 31–60 days | 17 | \~0% | \~317 | \~34.5 |

The 60+ days row was not read during the session. Older postings have more views partly because they have been visible longer, a confounder to correct with per-day rates.

**3. Apply rate falls as postings age (postings with apply data only)**

| Days open | Postings | Avg views | Avg applies | Apply rate |
| --- | --- | --- | --- | --- |
| Same day | 22,311 | 54.8 | 10.8 | 19.8% |
| 1–7 days | 660 | 38.4 | 4.0 | 10.4% |
| 8–30 days | 327 | 126.3 | 7.8 | 6.2% |
| 30+ days | 21 | \~337.7 | \~24.4 | \~7.2% |

The 30+ row has only 21 postings, too few to trust on its own.

**4. A few companies have most postings open long** (companies with at least 20 postings)

| Company | Postings | Long-open (>7 days) | % long-open | Avg days open | Max days open |
| --- | --- | --- | --- | --- | --- |
| Discover Financial Services | 54 | 52 | 96.3% | 23.9 | 25 |
| Aon | 111 | 96 | 86.5% | 21.7 | 25 |
| Varsity Tutors | 45 | 35 | 77.8% | 13.4 | 18 |

Average close to max suggests batches of postings reposted together (evergreen or bulk refreshes). For the product, this should read as "this posting looks like an evergreen listing", never as an accusation against a named company.

## Step 5: Ghost-job model (session 2, Nov 2)

A logistic regression in BigQuery ML ranks postings by stale risk with **ROC AUC 0.90**. Its top tier (1.2% of postings) is 53% actually stale, about 30 times the 1.79% base rate.

**Label and leakage**

- **Proxy label:** `is_stale = days_open > 7`. True for 2,222 of 123,849 postings (1.79%).
- **Excluded as leaky:** `days_open`, `is_reposted` and `original_listed_at` (the label is built from them), `views` and `applies` (they grow with age), and `expires_at` and `closed_at` (future information).
- **Leave-one-out company rate:** `company_stale_rate_loo` = the company's stale share across its *other* postings, so a posting never sees its own label. It is NULL for 15,933 rows (single-posting or unnamed companies).
- **Features used:** experience level, work type, remote, application type, has salary, description length, senior-title keyword, company's other postings and the LOO stale rate.

**Training:** `LOGISTIC_REG` with `auto_class_weights = TRUE` (for the 1.79% imbalance), a random 80/20 split and `enable_global_explain`. Running `ML.EVALUATE` before training had finished gave a "model was not evaluated" error; once training completed, it worked.

**Evaluation (held-out 20%)**

| Metric | Value | Meaning |
| --- | --- | --- |
| ROC AUC | 0.90 | Ranks a stale posting above a fresh one 90% of the time |
| Recall | 70.6% | Catches about 7 in 10 stale postings |
| Precision | 19.7% | 1 in 5 flags correct, 11 times the base rate |
| Accuracy | 94.3% | Misleading: always predicting "not stale" scores 98.2% |
| F1 | 0.31 | For comparing versions |
| Log loss | 0.35 | For comparing versions |

**Feature importance (`ML.GLOBAL_EXPLAIN`)**

| Feature | Attribution |
| --- | --- |
| company\_stale\_rate\_loo | 0.45 |
| description\_length | 0.23 |
| application\_type | 0.21 |
| experience\_level | 0.20 |
| is\_remote, work\_type, is\_senior\_title, has\_salary | 0.17–0.19 |
| company\_other\_postings | 0.08 |

**Threshold trade-off (`ML.ROC_CURVE`, held-out data)**

| Threshold | Flagged | Precision | Recall |
| --- | --- | --- | --- |
| 0.53 | 1,484 | 20.5% | 68.3% |
| 0.66 | 989 | 27.1% | 60.2% |
| 0.74 | 738 | 33.3% | 55.3% |
| 0.89 | 491 | 42.0% | 46.3% |
| 0.99 | 252 | 59.9% | 33.9% |

Passing a list of thresholds as the second argument to `ML.ROC_CURVE` failed ("argument 2 must be a relation"). Leaving it out uses the held-out data and BigQuery's own thresholds.

**Risk tiers (all postings, `posting_scores`)**

| Tier | Rule | Postings | Actually stale |
| --- | --- | --- | --- |
| High | score ≥ 0.99 | 1,503 (1.2%) | 53.1% |
| Medium | 0.74–0.99 | 2,348 (1.9%) | 20.5% |
| Low | < 0.74 | 119,998 (96.9%) | 0.8% |

High plus Medium (about 3% of postings) hold about 58% of all stale postings. The scores are not true probabilities because of class weights, so users should see tiers, never raw scores.

**Known weakness for v2:** the company feature dominates. Every posting from Amazon (343), Aon (111) and Discover (54) lands in High, even though only 71%, 86% and 96% respectively are stale. Options: compute the company rate from past data only, cap its influence, or show it as separate context ("this employer often reposts") rather than a per-job verdict.

## Step 6: Data Studio dashboard

A dashboard in Data Studio (formerly Looker Studio) reads live from one lean BigQuery table and shows the model's results with filters.

**Data:** `jobs_curated.dashboard_postings` joins curated postings with `posting_scores`, adds `days_open_bucket` and `views_with_apply_data`, and leaves out `description` so chart queries stay tiny. Connected through the BigQuery connector (authorized once); the data source is embedded in the report.

**Calculated fields and renames** (set in the data source editor)

| Field | Formula / change | Type |
| --- | --- | --- |
| Apply rate | `SUM(applies) / SUM(views_with_apply_data)` | Percent |
| stale\_rate | `SUM(CASE WHEN actual_is_stale THEN 1 ELSE 0 END) / COUNT(job_id)` | Percent |
| High-risk postings | `SUM(CASE WHEN risk_tier = "1. High" THEN 1 ELSE 0 END)` | Number |
| Company | renamed from `company_name` | Text |
| Postings | renamed from `job_id`, aggregation Count | Number |

**Layout**

| Area | Component | Shows |
| --- | --- | --- |
| Top | Title text | Get Connected · Job Market Intelligence |
| Row 1 | 4 scorecards | 123.8K postings · 24.4K companies · 1,503 high-risk · 19.07% apply rate |
| Right column | 3 drop-down filters | experience\_level, is\_remote, work\_type |
| Left | Bar chart | Stale rate by risk tier: High \~53%, Medium \~20%, Low \~1% |
| Left, below | Bar chart | Apply rate by days open: \~20%, \~10%, \~6%, \~7% |
| Right | Table | Companies by high-risk postings, with postings and stale rate |

**Concepts learned**

- Each chart sends a live query to BigQuery, so feed the dashboard one lean table and keep the logic in SQL.
- Ratios are computed from sums (`SUM(a) / SUM(b)`), not averages of per-row ratios.
- Dragging a field onto empty canvas creates a new chart; picking a field on a chart's pill changes that chart.
- Clicking a bar or table row applies a cross-filter to the whole page; clear it with the chip's X or Reset.
- Built-in `Record Count` can't be renamed; use a counted field such as `Postings` instead.

**Finished (session 3, Nov 3):** the first card now shows Postings, the table is widened under the filters with full headers, and the report is renamed *Get Connected - Job Market Intelligence*. The filters were tested in View mode: Entry level shows 36.7K postings, 6.2K companies, 471 high-risk and a 15.13% apply rate (vs 19.07% overall). 29.4K postings (\~24%) have a null experience level, a data-quality gap to label as "Not specified".

[Open the dashboard](https://datastudio.google.com/u/0/reporting/89a08fb7-d0ec-4893-a707-fa13c5baea76/page/HejCG)

## Step 7: Skill extraction (session 3, Nov 3)

The Natural Language API proved too generic for job skills, so a 39-skill regex dictionary in SQL tagged all 123,849 postings. Tech skills show 2–3× the average stale rate.

**Part 1: Natural Language API (pre-trained ML API)**

1. Exported a reproducible random sample of 50 descriptions (first 3,000 characters each) to Cloud Shell with `bq query --format=json`, ordered by `FARM_FINGERPRINT(job_id)`.
2. A Python script (`extract.py`) called `analyze_entities` on each and wrote one JSON line per entity.
3. Loaded 5,225 entities into `jobs_curated.job_entities` with `bq load --source_format=NEWLINE_DELIMITED_JSON`. Cost: about 150 of the 5,000 free units per month.

| Entity type | Entities | Distinct names |
| --- | --- | --- |
| OTHER | 3,475 | 1,959 |
| PERSON | 542 | 290 |
| ORGANIZATION | 349 | 249 |
| LOCATION | 285 | 187 |
| NUMBER | 235 | 97 |
| CONSUMER\_GOOD | 133 | 80 |
| Other types (event, work of art, price, date, phone) | 206 | — |

The most common entities were generic words ("skills", "training", "benefits", "work", "procedures", "education", "management") with salience around 0.004–0.014. The API has no skill type, so general-purpose models miss domain concepts.

**Part 2: Skill dictionary in SQL**

`skill_dictionary` holds 39 skills, each with a regex and a category (Tech, Office, Healthcare, Business, Soft skill, Trades). `posting_skills` cross-joins every posting with every skill and keeps matches from `REGEXP_CONTAINS(LOWER(description), pattern)`. `\b` word boundaries stop "excel" matching "excellent" and "java" matching "javascript".

| Top skills | Postings | Share |
| --- | --- | --- |
| Communication | 34,944 | 28.2% |
| Leadership | 29,355 | 23.7% |
| Sales | 28,777 | 23.2% |
| Customer service | 26,284 | 21.2% |

"Sales" is likely over-counted, since the pattern also matches "sales tax" or "our sales team" in non-sales jobs. Dictionaries match words, not meaning.

**Part 3: Skills vs stale postings** (skills with at least 500 postings; overall stale rate 1.79%)

| Skill | Postings | % stale | Apply rate |
| --- | --- | --- | --- |
| Machine learning | 1,725 | 4.99% | 24.9% |
| Tableau | 1,245 | 4.42% | 19.0% |
| Agile / Scrum | 6,151 | 3.76% | 27.0% |
| AWS | 3,245 | 3.33% | 31.6% |

Tech postings are 2–3× more likely to stay open over a week, yet they also draw higher apply rates. Many may be hard-to-fill roles rather than ghost jobs, a confounder that needs hiring-outcome data to separate.

**Three approaches compared**

| Approach | Pros | Cons |
| --- | --- | --- |
| Pre-trained API | No setup | Generic; no skill concept |
| Skill dictionary (used) | Precise, cheap, scales to all postings | Only finds listed skills; no context |
| LLM via BigQuery ML (v2) | Finds any skill, understands context | Per-call cost, slower, needs output checks |

## Step 8: Streaming pipeline (session 3, Nov 3)

New postings now stream from a simulator through Pub/Sub into BigQuery in seconds and get a ghost-job risk score automatically. A Dataflow job carried the same stream and was drained when done.

1. **Pub/Sub basics.** Created topic `new-postings` and a debug pull subscription; published one JSON message and pulled it back (`ACK_STATUS: SUCCESS`). A second pull returned nothing, because acknowledged messages aren't redelivered.
2. **Permissions.** Granted Pub/Sub's service account (`service-${PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com`) the `roles/bigquery.dataEditor` role. In the cloud, nothing has access until you grant it.
3. **BigQuery subscription.** `new-postings-to-bq` writes every message into `jobs_raw.postings_stream`, mapping JSON fields to same-named columns (`--use-table-schema --drop-unknown-fields`). A test message appeared as a row within seconds.
4. **Simulator.** `simulate.py` reads 100 random postings from BigQuery and publishes one every 0.5 s with a `sent_at` timestamp. The table grew to 101 rows while it ran.
5. **Real-time scoring.** View `jobs_curated.stream_scored` rebuilds the model's features from the stream and runs `ML.PREDICT`. The company stale rate comes from history only, the production-correct (leak-free) version.
6. **Dedupe.** A second simulator run re-sent the same 100 postings (201 raw rows). `QUALIFY ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY sent_at DESC) = 1` in the view brought it back to 101. The raw table keeps every message; the view serves one row per job.
7. **Dataflow.** Launched the Google template `PubSub_to_BigQuery_Flex` (1 worker, e2-standard-2) reading its own subscription `new-postings-dataflow` into `jobs_raw.postings_dataflow`. It took about 7 minutes to start, delivered all 100 simulated postings, then was drained (`Listed 0 items` = stopped).

**Live scoring check**

| Tier | Streamed postings | Share | Historical share |
| --- | --- | --- | --- |
| High | 1 | 1% | 1.2% |
| Medium | 1 | 1% | 1.9% |
| Low | 99 | 98% | 96.9% |

The stream matches historical proportions, so there's no sign of training/serving skew. Riskiest live postings: *Plumber* at Alamo Colleges District (score 1.0, High) and *Embedded Sensor/EW Real-Time Software Engineer* at Georgia Tech Research Institute (0.927, Medium).

**Concepts learned**

- **Batch vs streaming:** process files later vs process each event as it happens.
- **Topic / subscription:** each subscription gets its own copy of every message, so consumers are decoupled.
- **At-least-once delivery:** messages can arrive twice, so streaming consumers must deduplicate.
- **Service account:** a robot identity a Google service runs as; it needs explicit IAM roles.
- **Training/serving skew:** live features built differently from training features; check tier proportions.
- **Dataflow (Apache Beam):** managed workers for transforming streams in flight. Streaming jobs bill until stopped; **drain** finishes in-flight data, **cancel** stops immediately.

## Step 9: Scheduled pipeline (session 4, Nov 4)

A BigQuery scheduled query now runs every night at 05:00 UTC (midnight Eastern), scores the live stream and writes that day's risk-tier counts to `daily_risk_snapshot`. It's idempotent, so reruns and backfills never duplicate a day.

| Orchestration option | Best for |
| --- | --- |
| BigQuery scheduled queries (used) | SQL on a timer; simplest |
| Dataform | Many SQL steps with dependencies, version-controlled |
| Cloud Composer (Airflow) | Complex multi-service workflows; \~$300+/month |

1. Enabled the BigQuery Data Transfer API (`bigquerydatatransfer.googleapis.com`), which runs scheduled queries.
2. Created the append-only history table `jobs_curated.daily_risk_snapshot` (`snapshot_date`, `risk_tier`, `postings`) with `CREATE TABLE IF NOT EXISTS`.
3. Wrote the query using `@run_date`, a parameter only the scheduler fills; clicking Run gives "parameter 'run\_date' not found" by design.
4. The first schedule, made in the console, landed in location **US** and failed: "Dataset gc-job-intel:jobs\_curated was not found in location US". It was recreated in Cloud Shell with `bq mk --transfer_config --location=us-central1`, after a one-time authorization.
5. A test run (`bq mk --transfer_run`) plus the automatic run on creation produced 6 rows instead of 3. The query was changed to delete the day, then insert the day, and the rerun gave exactly 3 rows.

| snapshot\_date | risk\_tier | postings |
| --- | --- | --- |
| 2026-11-04 | 1. High | 1 |
| 2026-11-04 | 2. Medium | 1 |
| 2026-11-04 | 3. Low | 99 |

**Concepts learned**

- **Orchestration:** pipelines run on a schedule, not by hand.
- **Append-only snapshot table:** one dated set of rows per run builds a trend history.
- **Location:** a job runs in one location and can only see datasets there.
- **Idempotency:** same result however many times a run repeats; delete-then-insert by date.
- **Backfill:** rerun a past date with `--run_time`.

## Step 10: Spark on Dataproc Serverless (session 5, Nov 5)

A PySpark job on Dataproc Serverless read `posting_skills` from BigQuery, counted which skills appear together in the same posting, and wrote `jobs_curated.skill_pairs` back. It succeeded in 2 min 9 sec, and billing stopped when it ended.

|  | Dataproc clusters | Dataproc Serverless (used) |
| --- | --- | --- |
| Setup | You create and size VMs | None; submit a job |
| Billing | Until the cluster is deleted | Only while the job runs |

1. Enabled `dataproc.googleapis.com`, turned on Private Google Access for the `default` subnet in us-central1, and gave the default compute service account `roles/dataproc.worker`.
2. Wrote `skill_pairs.py`: read the table with the Spark BigQuery connector, self-join on `job_id`, keep `skill_a < skill_b` (each pair once), group and count, and write back with `writeMethod=direct`.
3. Submitted with `gcloud dataproc batches submit pyspark … --version=2.2`. The first attempt failed with "--deps-bucket was not specified", because a local script must be staged in Cloud Storage first; adding `--deps-bucket=gs://gc-job-intel-lake` fixed it.

| Rank | Skill pair | Postings |
| --- | --- | --- |
| 1 | Customer service + Sales | 10,839 |
| 2 | Communication + Leadership | 9,543 |
| 3 | Communication + Sales | 9,540 |
| 4 | Communication + Customer service | 9,184 |
| 5 | Communication + Problem solving | 8,935 |
| 11 | Budgeting + Leadership | 6,578 |
| 13 | Inventory management + Sales | 5,459 |
| 14 | Excel + Leadership | 5,244 |

Communication is the hub skill, and pairs form role clusters (sales and service, management, retail operations). Pairs with Sales are inflated by the over-broad `\bsales\b` pattern. Per-skill neighbours (for example, what Python pairs with) are the basis for "if you know X, you're close to Y" suggestions.

**Concepts learned**

- **Spark** splits work across machines; **PySpark** is its Python API; a **DataFrame** is a distributed table.
- **Lazy evaluation:** nothing runs until an action such as `show()` or `save()`.
- **Self-join** to build pairs; `a < b` removes duplicates and self-pairs.
- **Staging:** remote compute can't see Cloud Shell files, so code goes to Cloud Storage first.
- **Choose Spark over BigQuery SQL** for existing Spark code, logic that doesn't fit SQL, or processing raw lake files.

## Concepts glossary

| Concept | Meaning | Where it came up |
| --- | --- | --- |
| Columnar storage | BigQuery stores each column separately and bills by bytes of columns read, not rows | Query 1 read 3.16 MB of a 515 MB table |
| `SELECT *` cost | Reads every column, including the huge `description` | Avoid on large tables; use Preview (free) |
| Bytes estimate | The editor shows "This query will process X" before you run | Check it every time |
| Free tier | First 1 TB of queries and 10 GB of storage per month are free | All session 1 work stayed inside it |
| Hive-style partitioning | Folder names like `key=value` (`ingest_date=2026-11-01`) | Lake layout |
| Table partitioning | Splits a table by a date column so filters skip other dates | `PARTITION BY listed_date` |
| Clustering | Sorts data within partitions by chosen columns | `CLUSTER BY company_name, experience_level` |
| Grain | What one row of a table represents | Job-level vs company-level tables |
| `QUALIFY` + `ROW_NUMBER()` | Filters on a window function to keep one row per key | Dedupe by `job_id` |
| Window function | A calculation across rows without collapsing them | `SUM(COUNT(*)) OVER ()` for % of total |
| `CASE WHEN` | Turns a number into labeled buckets | Days-open buckets |
| `SAFE_DIVIDE` | Returns NULL instead of an error when dividing by zero | Apply rate |
| `APPROX_QUANTILES` | Fast percentiles (min, quartiles, max) | `days_open` distribution |
| Data profiling | Checking counts, ranges and missing values before modeling | Found 81% missing `applies` |
| Class imbalance | The interesting outcome is rare (about 2% here) | Judge models on precision and recall, not accuracy |
| Confounder | A hidden factor driving both variables | Older postings have more views simply from more time |
| Minimum sample threshold | Ignore groups too small to be reliable | `total_postings >= 20` |
| Label leakage | Feeding the model the same information used to build its label | Next session's main topic |
| Saved query | SQL stored in BigQuery with version history | `03_…`, `04_…`, `06_…` |
| View | A saved query that acts like a virtual table | Planned for the feature layer |

**Added in session 2**

| Concept | Meaning | Where it came up |
| --- | --- | --- |
| Proxy label | A measurable stand-in for an outcome with no ground truth | `is_stale = days_open > 7` |
| Label leakage | Features that encode the label or the future | Excluded days\_open, views, applies, expiry |
| Leave-one-out encoding | A group rate computed without the row's own label | `company_stale_rate_loo` |
| Logistic regression | Simple, interpretable yes/no model outputting a score 0–1 | `ghost_model_v1` |
| Class weights | Up-weight rare positives so the model can't ignore them | `auto_class_weights = TRUE` |
| Held-out evaluation | Grade the model on rows it never trained on | 20% random split |
| ROC AUC | Chance a random positive is ranked above a random negative | 0.90 |
| Precision / recall | Share of flags that are right / share of positives caught | 19.7% / 70.6% at 0.5 |
| Threshold | Score cut-off for a flag; a product decision | Tiers at 0.74 and 0.99 |
| Global explain | Ranks features by overall contribution | Company rate 0.45 |
| `ML.PREDICT` + `UNNEST` | Score rows; unpack the probability array | `posting_scores` |
| Calculated field | Formula computed at query time in Data Studio | Apply rate, stale\_rate |
| Cross-filter | Clicking a chart element filters the whole page | Accidental company filters |

**Added in session 3**

| Concept | Meaning | Where it came up |
| --- | --- | --- |
| Pre-trained ML API | A Google model called over the network, no training | Natural Language API |
| Entity analysis | Finds named things with a type and salience | `analyze_entities` |
| Salience | How central an entity is to the text, 0–1 | Generic words \~0.005 |
| `FARM_FINGERPRINT` | Hash used for reproducible sampling | Same 50 postings every run |
| JSONL | One JSON object per line; easy to load | `entities.jsonl` |
| Regex word boundary `\b` | Match whole words only | excel vs excellent |
| `CROSS JOIN` | Pair every row with every row of another table | postings × skills |
| `HAVING` | Filter groups after aggregation | Skills with ≥ 500 postings |

## Gotchas and fixes

| What happened | Why | Fix / habit |
| --- | --- | --- |
| Pasting several commands at once skipped some | `gcloud` paused for a y/N prompt and swallowed the next lines | Paste one command at a time; wait for the prompt to return |
| Folder created as `Raw/` | Cloud Storage paths are case-sensitive | Deleted it and recreated `raw/`; always use lowercase paths |
| A URL typed into the console search bar | The console's search bar is not the browser address bar | Use the browser's address bar, or click the search result |
| SQL pasted into Cloud Shell gave "command not found" | The terminal runs bash, not SQL | Run SQL in BigQuery Studio, or wrap it in `bq query --use_legacy_sql=false '...'` |
| Cloud Shell kept covering the page | The terminal panel was maximized | Minimize it (\_) or close it (X); files persist |
| Picked a Notebook instead of the dataset on Kaggle | Search results mix notebooks and datasets | The table icon means dataset, `<>` means notebook; check the author |
| A search result named "BigQuery Studio" points to Spark | That result is Managed Apache Spark | Choose the *BigQuery* product result |

**Added in session 2**

| What happened | Why | Fix / habit |
| --- | --- | --- |
| SQL typed into Cloud Shell again | Terminal runs bash | Close Cloud Shell; use BigQuery Studio |
| `ML.EVALUATE` said the model was not evaluated | Ran it while training was still in progress | Wait for "created a new model", then rerun |
| `ML.ROC_CURVE` error "argument 2 must be a relation" | Second argument must be a table, not a list | Omit it to use held-out data |
| New SQL pasted over a saved query tab | Pasted into `09_explain_ghost_model` | Ctrl+Z or close without saving; use a new tab |
| Dragging `company_name` created a table | Dropping on empty canvas makes a new chart | Pick fields from the chart's pill instead |
| Numbers suddenly dropped (529, 1.0, 0) | A click on a bar or row applied a cross-filter | Click X on the filter chip or Reset |
| Couldn't rename Record Count | Built-in field | Rename fields in the data source editor; use `Postings` |
| Two dropdowns overlapped after moving | Drag stacked them | Drag apart; Arrange → Distribute |

**Added in session 3**

| What happened | Why | Fix / habit |
| --- | --- | --- |
| "Table skill\_dictionary was not found" | Query 14 was saved but never run | Saving stores SQL only; click Run |
| Table got taller instead of wider | Dragged a corner handle | Drag the middle handle on the side, or use Style → Wrap text |
| Dropdowns moved instead of the table | The wrong item was selected | Check the panel title before dragging |

**Added for streaming**

| What happened | Why | Fix / habit |
| --- | --- | --- |
| `$'\E[200~gcloud': command not found` | Terminal paste glitch | Paste again |
| gcloud commands typed in the BigQuery tab | Wrong tool | gcloud / bq go in Cloud Shell; SQL goes in BigQuery Studio |
| `simulate.py: No such file or directory` | Cloud Shell restarted in `~` | `cd ~/skills`; check the prompt's folder |
| Second simulator run doubled the counts | Same 100 postings re-sent | Dedupe in the view with `QUALIFY ROW_NUMBER()` |
| `Unexpected keyword ROWS` | `rows` is reserved in BigQuery SQL | Use another name (`row_count`) or backticks |
| Dataflow sat in Queued \~7 min | Launcher and worker VMs start slowly | Wait and Refresh; check logs if over 10 min |
| Job showed Draining for a few minutes | Draining finishes in-flight data first | Recheck with `jobs list --status=active` |

**Added for scheduling (session 4)**

| What happened | Why | Fix / habit |
| --- | --- | --- |
| "parameter 'run\_date' not found" | Clicked Run; only the scheduler fills `@run_date` | Schedule it; don't run manually |
| Hourly schedule by default | Console default | Set Days and a UTC time (05:00 = midnight Eastern) |
| "Dataset … not found in location US" | Schedule defaulted to US; data is in us-central1 | Recreate with `--location=us-central1` |
| Snapshot had 6 rows, not 3 | Auto run on creation plus a manual run; plain INSERT | Delete the day, then insert the day |

## Next steps and open items

Next session focuses on the Coursera certificate (graded quizzes and labs), then model v2.

- [x] Define a proxy label and leak-free features (leave-one-out company rate)
- [x] Train a first BigQuery ML classifier and evaluate it on precision and recall
- [x] Build a Data Studio dashboard: postings, risk tiers, apply rate, company table, filters
- [x] Finish the dashboard: Postings label, table headers and alignment, report name, test filters
- [x] Extract skills: Natural Language API test, then a skill dictionary across all postings
- [ ] Build a streaming path (done in session 3): Pub/Sub, BigQuery subscription, real-time scoring view, Dataflow
- [ ] Schedule the pipeline (session 4) and run Spark on Dataproc Serverless (session 5); both done
- [ ] Add a skills chart to the dashboard (top skills and % stale by skill)
- [ ] Label null experience levels as "Not specified"
- [ ] Model v2: reduce reliance on the company feature; add skills and per-day rates as features
- [ ] Skills v2: try an LLM (Gemini via BigQuery ML) for context-aware extraction
- [ ] Check the Kaggle dataset's license
- [ ] Move the SQL into a GitHub repo (`gc-job-intel`)
- [ ] Decide whether to also earn the Coursera certificate (graded items only) or stay fully project-first
- [ ] Later: switch the data source to a licensed API (for example Adzuna or USAJOBS) before any product use

## Appendix A: Shell commands (Cloud Shell)

Run in order to rebuild the setup from scratch.

**Set project and region**

```bash
gcloud config set project gc-job-intel
gcloud config set compute/region us-central1
```

**Enable APIs and verify**

```bash
gcloud services enable \
  bigquery.googleapis.com \
  storage.googleapis.com \
  pubsub.googleapis.com \
  dataflow.googleapis.com \
  language.googleapis.com \
  aiplatform.googleapis.com

gcloud services list --enabled | grep -E "bigquery|storage|pubsub|dataflow|language|aiplatform|compute"
```

**Create the lake bucket and warehouse datasets**

```bash
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
```

**Verify uploaded files**

```bash
gcloud storage ls -r "gs://gc-job-intel-lake/raw/**" | head -30
gcloud storage du -s -r gs://gc-job-intel-lake/raw/
```

**Load postings into BigQuery and inspect the schema**

```bash
bq load \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  --allow_quoted_newlines \
  --max_bad_records=100 \
  jobs_raw.postings \
  "gs://gc-job-intel-lake/raw/source=linkedin_kaggle/ingest_date=2026-11-01/postings.csv"

bq show jobs_raw.postings
```

## Appendix B: SQL queries (BigQuery Studio)

Numbered in the order they were run; saved names in brackets.

**01 – Profile the raw data** (not saved)

```sql
SELECT
  COUNT(*) AS total_postings,
  COUNT(DISTINCT company_name) AS companies,
  DATE(TIMESTAMP_MILLIS(CAST(MIN(listed_time) AS INT64))) AS earliest_listed,
  DATE(TIMESTAMP_MILLIS(CAST(MAX(listed_time) AS INT64))) AS latest_listed
FROM `gc-job-intel.jobs_raw.postings`;
```

**02 – Ghost-job signals on raw data** (not saved)

```sql
SELECT
  COUNTIF(listed_time > original_listed_time) AS reposted_listings,
  ROUND(100 * COUNTIF(listed_time > original_listed_time) / COUNT(*), 1) AS pct_reposted,
  DATE(TIMESTAMP_MILLIS(CAST(MIN(original_listed_time) AS INT64))) AS earliest_original_listing,
  ROUND(AVG(views), 1) AS avg_views,
  ROUND(AVG(applies), 1) AS avg_applies,
  COUNTIF(applies IS NULL) AS postings_without_apply_data
FROM `gc-job-intel.jobs_raw.postings`;
```

**04 – Create the curated postings table** (saved as `04_create_curated_postings`)

```sql
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.postings`
PARTITION BY listed_date
CLUSTER BY company_name, experience_level
AS
SELECT
  job_id,
  TRIM(company_name) AS company_name,
  TRIM(title) AS title,
  description,
  location,
  formatted_work_type AS work_type,
  formatted_experience_level AS experience_level,
  IFNULL(remote_allowed, 0) = 1 AS is_remote,
  application_type,
  views,
  applies,
  normalized_salary,
  TIMESTAMP_MILLIS(CAST(original_listed_time AS INT64)) AS original_listed_at,
  TIMESTAMP_MILLIS(CAST(listed_time AS INT64)) AS listed_at,
  DATE(TIMESTAMP_MILLIS(CAST(listed_time AS INT64))) AS listed_date,
  TIMESTAMP_MILLIS(CAST(expiry AS INT64)) AS expires_at,
  TIMESTAMP_MILLIS(CAST(closed_time AS INT64)) AS closed_at,
  listed_time > original_listed_time AS is_reposted,
  TIMESTAMP_DIFF(
    TIMESTAMP_MILLIS(CAST(listed_time AS INT64)),
    TIMESTAMP_MILLIS(CAST(original_listed_time AS INT64)),
    DAY) AS days_open,
  CURRENT_TIMESTAMP() AS _loaded_at
FROM `gc-job-intel.jobs_raw.postings`
QUALIFY ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY listed_time DESC) = 1;
```

**Check the curated table** (not saved)

```sql
SELECT
  COUNT(*) AS rows_curated,
  COUNTIF(is_reposted) AS reposted,
  APPROX_QUANTILES(days_open, 4) AS days_open_quartiles,
  MAX(days_open) AS max_days_open
FROM `gc-job-intel.jobs_curated.postings`;
```

**05 – Days-open distribution** (not saved)

```sql
SELECT
  CASE
    WHEN days_open = 0 THEN '1. Same day'
    WHEN days_open <= 7 THEN '2. 1-7 days'
    WHEN days_open <= 30 THEN '3. 8-30 days'
    WHEN days_open <= 60 THEN '4. 31-60 days'
    ELSE '5. 60+ days'
  END AS days_open_bucket,
  COUNT(*) AS postings,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct,
  ROUND(AVG(views), 1) AS avg_views,
  ROUND(AVG(applies), 1) AS avg_applies
FROM `gc-job-intel.jobs_curated.postings`
GROUP BY days_open_bucket
ORDER BY days_open_bucket;
```

**03 – Apply rate by posting age** (saved as `03_apply_rate_by_age`)

```sql
SELECT
  CASE
    WHEN days_open = 0 THEN '1. Same day'
    WHEN days_open <= 7 THEN '2. 1-7 days'
    WHEN days_open <= 30 THEN '3. 8-30 days'
    ELSE '4. 30+ days'
  END AS days_open_bucket,
  COUNT(*) AS postings_with_applies,
  ROUND(AVG(views), 1) AS avg_views,
  ROUND(AVG(applies), 1) AS avg_applies,
  ROUND(100 * SAFE_DIVIDE(SUM(applies), SUM(views)), 1) AS apply_rate_pct
FROM `gc-job-intel.jobs_curated.postings`
WHERE applies IS NOT NULL
  AND views > 0
GROUP BY days_open_bucket
ORDER BY days_open_bucket;
```

**06 – Create company features** (saved as `06_create_company_features`)

```sql
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.company_features` AS
SELECT
  company_name,
  COUNT(*) AS total_postings,
  COUNTIF(days_open > 7) AS long_open_postings,
  ROUND(100 * COUNTIF(days_open > 7) / COUNT(*), 1) AS pct_long_open,
  ROUND(AVG(days_open), 1) AS avg_days_open,
  MAX(days_open) AS max_days_open,
  COUNTIF(applies IS NOT NULL) AS postings_with_apply_data,
  ROUND(100 * SAFE_DIVIDE(
    SUM(applies),
    SUM(IF(applies IS NOT NULL, views, 0))), 1) AS apply_rate_pct,
  ROUND(AVG(views), 1) AS avg_views
FROM `gc-job-intel.jobs_curated.postings`
WHERE company_name IS NOT NULL
GROUP BY company_name;
```

**Explore company features** (not saved)

```sql
SELECT *
FROM `gc-job-intel.jobs_curated.company_features`
WHERE total_postings >= 20
ORDER BY pct_long_open DESC
LIMIT 20;
```

### Session 2 queries

**07 – Create the training table** (`07_create_ghost_training`)

```sql
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.ghost_training` AS
WITH base AS (
  SELECT
    job_id,
    company_name,
    days_open > 7 AS is_stale,
    experience_level,
    work_type,
    is_remote,
    application_type,
    normalized_salary IS NOT NULL AS has_salary,
    LENGTH(description) AS description_length,
    REGEXP_CONTAINS(LOWER(title), r'senior|sr\.|lead|principal|staff') AS is_senior_title
  FROM `gc-job-intel.jobs_curated.postings`
),
company_totals AS (
  SELECT
    company_name,
    COUNT(*) AS n_postings,
    COUNTIF(is_stale) AS n_stale
  FROM base
  WHERE company_name IS NOT NULL
  GROUP BY company_name
)
SELECT
  b.*,
  c.n_postings - 1 AS company_other_postings,
  SAFE_DIVIDE(c.n_stale - IF(b.is_stale, 1, 0), c.n_postings - 1) AS company_stale_rate_loo
FROM base b
LEFT JOIN company_totals c USING (company_name);
```

**Check the training table**

```sql
SELECT
  COUNT(*) AS total_rows,
  COUNTIF(is_stale) AS stale_rows,
  ROUND(100 * COUNTIF(is_stale) / COUNT(*), 2) AS pct_stale,
  COUNTIF(company_stale_rate_loo IS NULL) AS rows_without_company_rate
FROM `gc-job-intel.jobs_curated.ghost_training`;
```

**08 – Train the model** (`08_train_ghost_model_v1`)

```sql
CREATE OR REPLACE MODEL `gc-job-intel.jobs_curated.ghost_model_v1`
OPTIONS (
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['is_stale'],
  auto_class_weights = TRUE,
  data_split_method = 'RANDOM',
  data_split_eval_fraction = 0.2,
  enable_global_explain = TRUE
) AS
SELECT * EXCEPT (job_id, company_name)
FROM `gc-job-intel.jobs_curated.ghost_training`;
```

**Evaluate**

```sql
SELECT *
FROM ML.EVALUATE(MODEL `gc-job-intel.jobs_curated.ghost_model_v1`);
```

**09 – Feature importance** (`09_explain_ghost_model`)

```sql
SELECT *
FROM ML.GLOBAL_EXPLAIN(MODEL `gc-job-intel.jobs_curated.ghost_model_v1`)
ORDER BY attribution DESC;
```

**10 – Threshold analysis** (`10_threshold_analysis`)

```sql
SELECT
  ROUND(threshold, 2) AS threshold,
  ROUND(recall, 3) AS recall,
  ROUND(SAFE_DIVIDE(true_positives, true_positives + false_positives), 3) AS precision,
  true_positives + false_positives AS postings_flagged
FROM ML.ROC_CURVE(MODEL `gc-job-intel.jobs_curated.ghost_model_v1`)
WHERE threshold >= 0.5
ORDER BY threshold;
```

**11 – Score every posting** (`11_score_postings`)

```sql
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.posting_scores` AS
SELECT
  job_id,
  company_name,
  is_stale AS actual_is_stale,
  p.prob AS stale_score,
  CASE
    WHEN p.prob >= 0.99 THEN '1. High'
    WHEN p.prob >= 0.74 THEN '2. Medium'
    ELSE '3. Low'
  END AS risk_tier
FROM ML.PREDICT(
  MODEL `gc-job-intel.jobs_curated.ghost_model_v1`,
  (SELECT * FROM `gc-job-intel.jobs_curated.ghost_training`)),
UNNEST(predicted_is_stale_probs) AS p
WHERE p.label = TRUE;
```

**12 – Tier performance** (`12_tier_performance`)

```sql
SELECT
  risk_tier,
  COUNT(*) AS postings,
  ROUND(100 * COUNTIF(actual_is_stale) / COUNT(*), 1) AS pct_actually_stale
FROM `gc-job-intel.jobs_curated.posting_scores`
GROUP BY risk_tier
ORDER BY risk_tier;
```

**13 – Dashboard table** (`13_create_dashboard_table`)

```sql
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.dashboard_postings` AS
SELECT
  p.job_id,
  p.company_name,
  p.title,
  p.experience_level,
  p.work_type,
  p.is_remote,
  p.application_type,
  p.listed_date,
  p.days_open,
  CASE
    WHEN p.days_open = 0 THEN '1. Same day'
    WHEN p.days_open <= 7 THEN '2. 1-7 days'
    WHEN p.days_open <= 30 THEN '3. 8-30 days'
    ELSE '4. 30+ days'
  END AS days_open_bucket,
  p.views,
  p.applies,
  IF(p.applies IS NOT NULL, p.views, NULL) AS views_with_apply_data,
  p.normalized_salary,
  s.stale_score,
  s.risk_tier,
  s.actual_is_stale
FROM `gc-job-intel.jobs_curated.postings` p
LEFT JOIN `gc-job-intel.jobs_curated.posting_scores` s USING (job_id);
```

### Session 3: Natural Language API (Cloud Shell)

**Setup and sample export**

```bash
mkdir -p ~/skills && cd ~/skills
pip install --user --quiet google-cloud-language

bq query --use_legacy_sql=false --format=json --max_rows=50 '
SELECT job_id, title, SUBSTR(description, 1, 3000) AS description
FROM `gc-job-intel.jobs_curated.postings`
WHERE description IS NOT NULL
ORDER BY FARM_FINGERPRINT(CAST(job_id AS STRING))
LIMIT 50' > sample.json
```

**extract.py**

```python
import json
from google.cloud import language_v1

client = language_v1.LanguageServiceClient()
rows = json.load(open("sample.json"))

with open("entities.jsonl", "w") as out:
    for i, r in enumerate(rows, 1):
        doc = language_v1.Document(
            content=r["description"],
            type_=language_v1.Document.Type.PLAIN_TEXT)
        resp = client.analyze_entities(request={"document": doc})
        for e in resp.entities:
            out.write(json.dumps({
                "job_id": int(r["job_id"]),
                "title": r["title"],
                "entity": e.name,
                "entity_type": language_v1.Entity.Type(e.type_).name,
                "salience": round(e.salience, 4)
            }) + "\n")
        print(f"{i}/{len(rows)} done: {r['title'][:50]}")
```

**Run, load and inspect**

```bash
python3 extract.py
bq load --source_format=NEWLINE_DELIMITED_JSON --autodetect jobs_curated.job_entities entities.jsonl
wc -l entities.jsonl

bq query --use_legacy_sql=false '
SELECT entity_type, COUNT(*) AS entities, COUNT(DISTINCT entity) AS distinct_names
FROM `gc-job-intel.jobs_curated.job_entities`
GROUP BY entity_type ORDER BY entities DESC'

bq query --use_legacy_sql=false '
SELECT LOWER(entity) AS entity, entity_type,
       COUNT(DISTINCT job_id) AS postings, ROUND(AVG(salience), 3) AS avg_salience
FROM `gc-job-intel.jobs_curated.job_entities`
GROUP BY entity, entity_type ORDER BY postings DESC LIMIT 25'
```

### Session 3: Skill dictionary (BigQuery Studio)

**14 – Skill dictionary** (`14_create_skill_dictionary`)

```sql
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.skill_dictionary` AS
SELECT * FROM UNNEST([
  STRUCT("Python" AS skill, r"\bpython\b" AS pattern, "Tech" AS category),
  ("SQL", r"\bsql\b", "Tech"),
  ("Java", r"\bjava\b", "Tech"),
  ("JavaScript", r"\bjavascript\b", "Tech"),
  ("AWS", r"\baws\b|amazon web services", "Tech"),
  ("Azure", r"\bazure\b", "Tech"),
  ("Google Cloud", r"google cloud|\bgcp\b", "Tech"),
  ("Kubernetes", r"\bkubernetes\b", "Tech"),
  ("Docker", r"\bdocker\b", "Tech"),
  ("Git", r"\bgit\b|github", "Tech"),
  ("Machine learning", r"machine learning", "Tech"),
  ("Tableau", r"\btableau\b", "Tech"),
  ("Power BI", r"power bi", "Tech"),
  ("Salesforce", r"\bsalesforce\b", "Tech"),
  ("SAP", r"\bsap\b", "Tech"),
  ("Excel", r"\bexcel\b", "Office"),
  ("Microsoft Office", r"microsoft office|ms office|microsoft 365", "Office"),
  ("Registered Nurse", r"\brn\b|registered nurse", "Healthcare"),
  ("CPR / BLS", r"\bcpr\b|\bbls\b", "Healthcare"),
  ("EMR / EHR", r"\bemr\b|\behr\b|electronic medical record", "Healthcare"),
  ("HIPAA", r"\bhipaa\b", "Healthcare"),
  ("Patient care", r"patient care", "Healthcare"),
  ("Project management", r"project management|\bpmp\b", "Business"),
  ("Agile / Scrum", r"\bagile\b|\bscrum\b", "Business"),
  ("Customer service", r"customer service", "Business"),
  ("Sales", r"\bsales\b", "Business"),
  ("Accounting", r"\baccounting\b", "Business"),
  ("CPA", r"\bcpa\b", "Business"),
  ("QuickBooks", r"quickbooks", "Business"),
  ("Budgeting", r"\bbudget", "Business"),
  ("Communication", r"communication skills", "Soft skill"),
  ("Leadership", r"\bleadership\b", "Soft skill"),
  ("Problem solving", r"problem[- ]solving", "Soft skill"),
  ("Teamwork", r"\bteamwork\b|team player", "Soft skill"),
  ("Bilingual / Spanish", r"\bbilingual\b|\bspanish\b", "Soft skill"),
  ("Forklift", r"\bforklift\b", "Trades"),
  ("CDL", r"\bcdl\b|commercial driver", "Trades"),
  ("OSHA", r"\bosha\b", "Trades"),
  ("Inventory management", r"inventory", "Trades")
]);
```

**15 – Tag postings with skills** (`15_create_posting_skills`)

```sql
CREATE OR REPLACE TABLE `gc-job-intel.jobs_curated.posting_skills` AS
SELECT p.job_id, d.skill, d.category
FROM `gc-job-intel.jobs_curated.postings` p
CROSS JOIN `gc-job-intel.jobs_curated.skill_dictionary` d
WHERE REGEXP_CONTAINS(LOWER(p.description), d.pattern);
```

**16 – Top skills** (`16_top_skills`)

```sql
SELECT
  skill,
  category,
  COUNT(*) AS postings,
  ROUND(100 * COUNT(*) / 123849, 1) AS pct_of_postings
FROM `gc-job-intel.jobs_curated.posting_skills`
GROUP BY skill, category
ORDER BY postings DESC
LIMIT 25;
```

**17 – Skills vs stale postings** (`17_skills_vs_stale`)

```sql
SELECT
  s.skill,
  s.category,
  COUNT(*) AS postings,
  ROUND(100 * COUNTIF(sc.actual_is_stale) / COUNT(*), 2) AS pct_stale,
  ROUND(100 * SAFE_DIVIDE(SUM(p.applies),
        SUM(IF(p.applies IS NOT NULL, p.views, 0))), 1) AS apply_rate_pct
FROM `gc-job-intel.jobs_curated.posting_skills` s
JOIN `gc-job-intel.jobs_curated.posting_scores` sc USING (job_id)
JOIN `gc-job-intel.jobs_curated.postings` p USING (job_id)
GROUP BY s.skill, s.category
HAVING postings >= 500
ORDER BY pct_stale DESC;
```

### Session 3: Streaming (Cloud Shell)

**Pub/Sub basics**

```bash
gcloud pubsub topics create new-postings
gcloud pubsub subscriptions create new-postings-debug --topic=new-postings
gcloud pubsub topics publish new-postings --message='{"job_id": 1, "title": "Test Data Engineer", "company_name": "Get Connected AI"}'
gcloud pubsub subscriptions pull new-postings-debug --auto-ack --limit=5
```

**BigQuery subscription**

```bash
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
```

**simulate.py**

```python
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
```

**Dataflow**

```bash
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
```

**18 – Real-time scoring view** (`18_create_stream_scored`)

```sql
CREATE OR REPLACE VIEW `gc-job-intel.jobs_curated.stream_scored` AS
WITH company_history AS (
  SELECT company_name,
         COUNT(*) AS n_postings,
         AVG(IF(is_stale, 1, 0)) AS stale_rate
  FROM `gc-job-intel.jobs_curated.ghost_training`
  WHERE company_name IS NOT NULL
  GROUP BY company_name
),
features AS (
  SELECT
    s.job_id, s.title, s.company_name, s.sent_at,
    s.experience_level, s.work_type, s.is_remote, s.application_type,
    s.normalized_salary IS NOT NULL AS has_salary,
    LENGTH(s.description) AS description_length,
    REGEXP_CONTAINS(LOWER(s.title), r'senior|sr\.|lead|principal|staff') AS is_senior_title,
    h.n_postings AS company_other_postings,
    h.stale_rate AS company_stale_rate_loo
  FROM `gc-job-intel.jobs_raw.postings_stream` s
  LEFT JOIN company_history h USING (company_name)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY s.job_id ORDER BY s.sent_at DESC) = 1
)
SELECT
  job_id, title, company_name, sent_at,
  ROUND(p.prob, 3) AS stale_score,
  CASE
    WHEN p.prob >= 0.99 THEN '1. High'
    WHEN p.prob >= 0.74 THEN '2. Medium'
    ELSE '3. Low'
  END AS risk_tier
FROM ML.PREDICT(
  MODEL `gc-job-intel.jobs_curated.ghost_model_v1`,
  (SELECT * FROM features)),
UNNEST(predicted_is_stale_probs) AS p
WHERE p.label = TRUE;
```

**19 / 20 – Stream checks**

```sql
SELECT risk_tier, COUNT(*) AS postings
FROM `gc-job-intel.jobs_curated.stream_scored`
GROUP BY risk_tier ORDER BY risk_tier;

SELECT title, company_name, stale_score, risk_tier, sent_at
FROM `gc-job-intel.jobs_curated.stream_scored`
ORDER BY stale_score DESC LIMIT 10;
```

### Session 4: Scheduled query

**History table**

```sql
CREATE TABLE IF NOT EXISTS `gc-job-intel.jobs_curated.daily_risk_snapshot` (
  snapshot_date DATE,
  risk_tier STRING,
  postings INT64
);
```

**Create, update and backfill the schedule (Cloud Shell)**

```bash
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
```

### Session 5: Spark on Dataproc Serverless (Cloud Shell)

**Setup**

```bash
cd ~/skills
gcloud services enable dataproc.googleapis.com
gcloud compute networks subnets update default --region=us-central1 --enable-private-ip-google-access

PROJECT_NUMBER=$(gcloud projects describe gc-job-intel --format="value(projectNumber)")
gcloud projects add-iam-policy-binding gc-job-intel \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/dataproc.worker" --condition=None
```

**skill\_pairs.py**

```python
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder.appName("skill-pairs").getOrCreate()

skills = (spark.read.format("bigquery")
          .option("table", "gc-job-intel.jobs_curated.posting_skills")
          .load())

a = skills.select("job_id", F.col("skill").alias("skill_a"))
b = skills.select("job_id", F.col("skill").alias("skill_b"))

pairs = (a.join(b, "job_id")
          .filter(F.col("skill_a") < F.col("skill_b"))
          .groupBy("skill_a", "skill_b")
          .agg(F.count("*").alias("postings"))
          .orderBy(F.desc("postings")))

pairs.show(20, truncate=False)

(pairs.write.format("bigquery")
      .option("writeMethod", "direct")
      .mode("overwrite")
      .save("gc-job-intel.jobs_curated.skill_pairs"))

spark.stop()
```

**Submit and query**

```bash
gcloud dataproc batches submit pyspark skill_pairs.py \
  --region=us-central1 \
  --batch=skill-pairs-$(date +%H%M) \
  --version=2.2 \
  --deps-bucket=gs://gc-job-intel-lake
```

```sql
SELECT skill_a, skill_b, postings
FROM `gc-job-intel.jobs_curated.skill_pairs`
ORDER BY postings DESC
LIMIT 15;
```
