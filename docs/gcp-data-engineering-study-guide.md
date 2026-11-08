# GCP Data Engineering Study Guide

Nov 5, 2026 · @Sunny

## How to use this guide

The certificate needs **19 graded quizzes** across the 4 courses: 4 + 5 + 4 + 6. The syllabus pages don't mark the labs as graded. Still do them: they're hands-on and the quizzes draw on them.

| Course | Graded quizzes | Labs | Listed time |
| --- | --- | --- | --- |
| 1. Data Lakes & Warehouses | 4 | 4 | 5 h |
| 2. Batch Pipelines | 5 | 4 | 12 h |
| 3. Streaming Pipelines | 4 | 4 | 8 h |
| 4. Smart Analytics, ML & AI | 6 | 5 | 7 h |

- **Order:** Courses 1 → 4.
- **Per module:** skim the notes here, watch only the lessons on gaps (marked **New to you**), then take the quiz. Items marked **You built this** you already know from gc-job-intel.
- **Labs** run in temporary Qwiklabs accounts with a timer. Read the steps before you click Start.
- These notes are my summaries of the public syllabus, not course text. The current course has been updated (lakehouse, Iceberg, Serverless Spark), so it differs a little from the original outline.

## Course 1: Build Data Lakes and Data Warehouses

The course centres on the **lakehouse**: open-format files in Cloud Storage, queried and governed through BigQuery. You built the lake + warehouse half; Iceberg, federated queries and governance are new.

| Module | Graded item | Labs |
| --- | --- | --- |
| 2. Modern data engineering | Warehouses, lakes and lakehouses concepts | — |
| 3. Lakehouse with Cloud Storage, open formats, BigQuery | Lakehouse features and benefits | Federated query with BigQuery and AlloyDB |
| 4. Modernizing warehouses with BigQuery | BigQuery and Lakehouse | Querying external data and Iceberg tables |
| 5. Advanced patterns and governance | Security and ML in the lakehouse | — |
| 6. Labs and best practices | — | Getting started with BigQuery ML; Vector search with BigQuery |

**Key concepts**

- **Data lake** (You built this): cheap object storage for raw files in any format; schema applied when read. Your `gs://gc-job-intel-lake`.
- **Data warehouse** (You built this): structured, governed tables for SQL analytics; schema applied when written. Your BigQuery datasets.
- **Lakehouse** (New to you): lake files stay in Cloud Storage in an open table format, and BigQuery queries them like tables. One copy of data, both flexibility and warehouse features.
- **Apache Iceberg** (New to you): an open table format adding transactions, schema evolution and time travel to files in a lake. **BigLake** tables let BigQuery read and govern Iceberg and other external files.
- **External vs native tables:** external tables read files where they sit (slower, no storage charge in BigQuery); native tables store data inside BigQuery (fastest).
- **Federated query** (New to you): query an operational database (AlloyDB, Cloud SQL) from BigQuery with `EXTERNAL_QUERY`, without copying the data.
- **Partitioning and clustering** (You built this): partition on a date to skip whole chunks; cluster on frequent filter columns to sort within partitions. Both cut bytes scanned.
- **Governance and security** (New to you): IAM roles at project, dataset and table level; column- and row-level security; **Dataplex** for catalog, lineage and data quality; **Sensitive Data Protection (DLP)** to find and mask personal data such as names and emails.
- **ML in the warehouse:** BigQuery ML (you built this) and **vector search** (New to you): store embeddings and find similar items with `VECTOR_SEARCH`, useful for matching candidates to jobs.

**Watch first:** module 3 (Iceberg, AlloyDB), module 4 "Lakehouse and external tables", module 5 governance and the DLP demo.

### My notes: Module 3, "Building a data lake foundation"

**Lakehouse in one line:** lake flexibility (store any data, raw, at scale) + warehouse discipline (enforced schema, fast queries), in one system instead of two.

**Storage layer**

- **Cloud Storage** is the main lakehouse storage on Google Cloud: object storage that scales without limit, is highly durable and costs little. It holds files of almost any type or size.
- It doesn't have to be the only store: in a **multi-cloud** setup, data can sit in another provider's object storage and still be part of the lakehouse.
- In my project: `gs://gc-job-intel-lake` is this layer.

**Three kinds of data a lake holds**

| Type | What it is | Course example (Cymbal) | My project example |
| --- | --- | --- | --- |
| Structured | Fixed rows and columns; predictable, easy to search and analyse | Customer lists, product catalogs, sales transactions | `postings.csv`, the BigQuery tables |
| Semi-structured | No rigid schema, but tags or keys give records a hierarchy; fields can vary per record | Order details as JSON | Pub/Sub messages and `entities.jsonl` |
| Unstructured | No predefined structure; hardest to process, but rich in insight with AI tools | Product reviews, support chat logs, product images | Job description text (mined with the Natural Language API and regex) |

**Likely quiz angles**

- A lake stores all three types; a traditional warehouse is built for structured data.
- JSON = semi-structured (keys give structure, fields can vary).
- Text, chat logs, images, audio = unstructured, and usually need ML/AI to extract value.

### My notes: Module 3, "Introduction to Apache Iceberg open table format"

**Big idea:** plain files in a lake are just files. Iceberg adds a table layer on top, so files in Cloud Storage behave like fast, reliable, queryable tables. In short, warehouse benefits on lake storage.

| Iceberg feature | What it means | Why it matters | Link to my project |
| --- | --- | --- | --- |
| Schema evolution | Add or rename columns without rewriting data or breaking existing apps | Requirements change all the time | If job postings gain a `salary_currency` field, the table adapts without a reload |
| Hidden partitioning | Iceberg decides and tracks partitions itself; queries don't need to know the file layout | Analysts get partition speed without managing partitions | I set `PARTITION BY listed_date` by hand; Iceberg does this automatically |
| Time travel | Query the table as it was at an earlier point in time | Reproduce last month's report exactly; audit and debug | BigQuery has a similar feature: `FOR SYSTEM_TIME AS OF` (up to 7 days back) |
| Atomic transactions | Many processes can read and write the same table at once without corrupting it; a change fully succeeds or fully fails | Safe concurrent pipelines | My nightly delete-then-insert could be wrapped in one transaction so a failure never leaves a day half-written |

**Likely quiz angles**

- Iceberg is an **open table format**, not a database or a storage service; the data still lives in Cloud Storage.
- Match each feature to its scenario: changing columns → schema evolution; "what did the data look like last month?" → time travel; many writers at once → atomic transactions; not managing file layout → hidden partitioning.
- Iceberg + Cloud Storage + BigQuery = the lakehouse pattern from the previous lesson.

## Course 2: Build Batch Data Pipelines

The course covers choosing batch, building pipelines in Dataflow and Serverless Spark, data quality, then orchestration and monitoring. You did Serverless Spark, quality and dedupe; Dataflow batch, Composer and Data Fusion are new.

| Module | Graded items | Labs |
| --- | --- | --- |
| 1. When to choose batch pipelines | When to choose batch data pipelines | — |
| 2. Design and build batch pipelines | Design and transformations | Batch pipeline with Serverless for Apache Spark; Batch pipeline with Dataflow Job Builder UI |
| 3. Control data quality | Data validation and schema evolution | Validate data quality with Serverless for Apache Spark |
| 4. Orchestrate and monitor | Orchestrations and DAGs; Observability | Building batch pipelines in Cloud Data Fusion |

**Key concepts**

- **Batch vs streaming:** batch processes a bounded set on a schedule (cheaper, simpler, higher latency); streaming processes events as they arrive. Choose batch when hours of delay are acceptable: daily reports, model retraining, backfills.
- **ETL vs ELT** (You built this): ETL transforms before loading; ELT loads raw first and transforms inside the warehouse with SQL, as you did with `jobs_raw` → `jobs_curated`.
- **Dataflow and Apache Beam** (New to you): you write a pipeline of **PCollections** (distributed datasets) and **PTransforms** (steps such as ParDo, GroupByKey); Dataflow runs it on autoscaling workers. The same code runs batch or streaming. **Job Builder** builds pipelines in a UI without code.
- **Serverless for Apache Spark** (You built this): Dataproc Serverless; submit PySpark without managing clusters, billed per job. Choose Spark for existing Spark code or logic that doesn't fit SQL.
- **Throughput and cost:** right-size workers, use autoscaling, filter and project columns early, avoid shuffling more data than needed.
- **Data quality** (You built this): validation rules (nulls, ranges, formats), cleansing, deduplication (your `QUALIFY ROW_NUMBER()`), and routing bad rows to an error table (a **dead-letter** pattern) instead of failing the job.
- **Schema evolution** (New to you): handling added or changed columns; additive changes (new nullable columns) are safe, renames and type changes break consumers.
- **Orchestration:** **Cloud Composer** (managed Apache Airflow) runs **DAGs**, directed acyclic graphs of tasks with dependencies, retries and schedules. You used the simpler option, scheduled queries.
- **Idempotency and backfills** (You built this): reruns must not duplicate data; your delete-then-insert by date.
- **Lineage:** tracking which tables feed which, through Dataplex.
- **Observability:** Cloud Logging, Cloud Monitoring metrics and alerting policies; job graphs in Dataflow show where time and data go.
- **Cloud Data Fusion** (New to you): visual, drag-and-drop pipeline builder (based on CDAP) with many connectors, for teams that prefer no code.

**Watch first:** module 2 Dataflow lessons, all of module 4 (Composer, DAGs, Data Fusion).

## Course 3: Build Streaming Data Pipelines

Nearly all graded work sits in module 3, one quiz per product. You built Pub/Sub, Dataflow and real-time BigQuery; Kafka, Beam windowing and Bigtable are new. The labs follow an esports scenario.

| Module | Graded items | Labs |
| --- | --- | --- |
| 2. Use cases and reference architectures | — | — |
| 3. Product deep dives | Pub/Sub and Managed Kafka; Dataflow; BigQuery; Bigtable | Stream data with pipelines; Apache Beam and Bigtable enrichment; Pub/Sub and BigQuery; Monitor chat with Streamlit |

**Key concepts**

- **Four streaming patterns:** streaming ETL (clean and load as data arrives), streaming AI/ML (score in real time, like your `stream_scored`), streaming applications (live features in an app), and **reverse ETL** (push warehouse results back into operational systems).
- **Pub/Sub** (You built this): topics and subscriptions, push vs pull, acknowledgement deadlines, **at-least-once** delivery (so dedupe), optional **exactly-once** and **ordering keys**, dead-letter topics for messages that keep failing, and message retention for replay.
- **Managed Service for Apache Kafka** (New to you): choose it when teams already use Kafka or need Kafka's ecosystem; choose Pub/Sub for a serverless, auto-scaling default.
- **Dataflow streaming** (You built this, basics): Beam pipelines that never end. **New to you:** **windows** group an endless stream into finite chunks: **fixed** (every 5 min), **sliding** (5-min window every 1 min), **session** (gaps in activity). **Watermarks** estimate when all data for a window has arrived; **triggers** decide when to emit results; **late data** handling decides what happens after.
- **Event time vs processing time:** when something happened vs when the pipeline saw it. Windows should use event time.
- **BigQuery for streaming** (You built this): BigQuery subscriptions, the **Storage Write API** for high-throughput ingest, and near-real-time queries on fresh rows.
- **Bigtable** (New to you): NoSQL wide-column store for millisecond reads and writes at huge scale. Design centres on the **row key**: rows are sorted by key, so put the most-queried attribute first and avoid hotspots (for example, don't start keys with a timestamp).
- **BigQuery vs Bigtable:** BigQuery for analytical scans across many rows; Bigtable for fast lookups of single rows by key (serving).
- **Drain vs cancel** (You built this): drain finishes in-flight data; cancel stops immediately.

**Watch first:** Dataflow (windowing and watermarks), Bigtable, and the Kafka architecture lesson.

## Course 4: Smart Analytics, Machine Learning, and AI

The course moves from prebuilt ML APIs to notebooks, production pipelines, BigQuery ML and AutoML. You built the API and BigQuery ML parts; notebooks, Vertex AI Pipelines and AutoML are new.

| Module | Graded item | Labs |
| --- | --- | --- |
| 2. Introduction to analytics and AI | Introduction to Analytics and AI | — |
| 3. Prebuilt ML APIs for unstructured data | Prebuilt ML model APIs | Natural Language API to classify text |
| 4. Big data analytics with notebooks | Big data analytics with notebooks | BigQuery in JupyterLab on Vertex AI |
| 5. Production ML pipelines | Production ML Pipelines | Running pipelines on Vertex AI |
| 6. Custom models with SQL in BigQuery ML | Custom model building in BigQuery ML | Bike trip duration (regression); Movie recommendations |
| 7. Custom models with Vertex AI AutoML | Custom model building with AutoML | — |

**Key concepts**

- **AI ⊃ ML ⊃ deep learning:** AI is the broad goal of machines doing intelligent tasks; ML learns patterns from data instead of hand-written rules; deep learning uses many-layered neural networks, best for images, audio and text.
- **Choosing an ML option, least to most effort:** prebuilt APIs (no training) → BigQuery ML (SQL) → AutoML (no code, your data) → custom training on Vertex AI (full control).
- **Prebuilt APIs** (You built this): Natural Language (entities, sentiment, **classification** into content categories, the lab's focus), Vision, Speech-to-Text, Translation. Fast, but generic, as your skills test showed.
- **Notebooks** (New to you): JupyterLab on Vertex AI Workbench. `%%bigquery df` runs SQL and returns a pandas DataFrame; then plot or model in Python.
- **Vertex AI Pipelines** (New to you): define ML steps (prepare data, train, evaluate, deploy) as a pipeline so they rerun reproducibly; **TensorFlow Hub** offers pretrained models to reuse.
- **BigQuery ML** (You built this): `CREATE MODEL`, `ML.EVALUATE`, `ML.PREDICT`, `ML.EXPLAIN`. Model types: **linear regression** (numbers, like trip duration), **logistic regression** (yes/no, your ghost-job model), **k-means** (clustering), **matrix factorization** (recommendations, the movie lab), boosted trees, DNNs, time series (ARIMA\_PLUS), and imported TensorFlow models.
- **Evaluation** (You built this): regression uses MAE, RMSE, R²; classification uses precision, recall, ROC AUC, log loss; accuracy misleads on imbalanced data.
- **AutoML** (New to you): upload labelled data and Vertex AI picks and tunes the model for vision, text or tabular data. Better accuracy than BigQuery ML for some problems, at higher cost and training time.

**Watch first:** modules 4, 5 and 7, and the BigQuery ML model-types lesson (regression and matrix factorization).

## Cheat sheet: which service, and common traps

| Need | Pick | Not |
| --- | --- | --- |
| Store raw files of any format cheaply | Cloud Storage | BigQuery |
| SQL analytics over large data | BigQuery | Bigtable, Cloud SQL |
| Millisecond lookups by key at huge scale | Bigtable | BigQuery |
| Transactional app database (OLTP) | Cloud SQL / AlloyDB / Spanner (global) | BigQuery |
| Query lake files with warehouse governance | BigLake / Iceberg tables | Copying files into BigQuery |
| Query an operational DB from BigQuery without copying | Federated query (`EXTERNAL_QUERY`) | Nightly exports |
| Event messaging, serverless | Pub/Sub | Kafka (unless already used) |
| Transform streaming or batch data in code | Dataflow (Apache Beam) | — |
| Run existing Spark / Hadoop code | Dataproc (Serverless or clusters) | Rewriting in SQL |
| No-code visual pipelines | Cloud Data Fusion | — |
| Multi-step workflows with dependencies | Cloud Composer (Airflow) | Scheduled queries |
| One SQL statement on a timer | BigQuery scheduled query | Composer (overkill) |
| ML on text, images, speech without training | Prebuilt ML APIs | AutoML |
| ML in SQL on warehouse data | BigQuery ML | Exporting to Python |
| Best model with no code | Vertex AI AutoML | — |
| Find and mask personal data | Sensitive Data Protection (DLP) | Manual review |

**Common traps**

- `LIMIT` does not reduce bytes billed; selecting fewer columns does.
- Partition on a date column; cluster on filter columns. BigQuery has no indexes.
- Pub/Sub is at-least-once: plan for duplicates.
- Streaming windows use **event time**; watermarks handle late data.
- Bigtable row keys starting with a timestamp create hotspots.
- Accuracy is misleading on imbalanced classes; use precision, recall or AUC.
- A BigQuery job must run in the same location as its datasets.
- Streaming Dataflow jobs bill until drained or cancelled.

## Sources

Syllabus details from the public Coursera course pages, read Nov 5, 2026. Concept notes are written for this guide, not copied from course material.

- [Data Engineering, Big Data, and Machine Learning on GCP Specialization](https://www.coursera.org/specializations/gcp-data-machine-learning)
- [Build Data Lakes and Data Warehouses on Google Cloud](https://www.coursera.org/learn/data-lakes-data-warehouses-gcp?specialization=gcp-data-machine-learning)
- [Build Batch Data Pipelines on Google Cloud](https://www.coursera.org/learn/batch-data-pipelines-gcp?specialization=gcp-data-machine-learning)
- [Build Streaming Data Pipelines on Google Cloud](https://www.coursera.org/learn/streaming-analytics-systems-gcp?specialization=gcp-data-machine-learning)
- [Smart Analytics, Machine Learning, and AI on Google Cloud](https://www.coursera.org/learn/smart-analytics-machine-learning-ai-gcp?specialization=gcp-data-machine-learning)
- Your project notes: [gc-job-intel Learning Report](https://claude.ai/artifact/8qKnA3auiKF1Z7y4JSwXBx)
