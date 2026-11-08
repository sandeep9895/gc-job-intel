# Intro to AI & ML on Google Cloud — Study Guide

Nov 6, 2026 · @Sunny

## How to use this guide

This works the same way as the Coursera specialization guide: watch only what's new, take the labs, then repeat each lab on gc-job-intel and point it at Get Connected. All notes here are my own summaries built from public syllabus pages, not copies of course material.

Each topic carries one marker:

- **You built this:** already done in gc-job-intel. Skim the video and go straight to the quiz.
- **New to you:** watch the lessons properly.
- **Get Connected tie-in:** where the concept turns into something the product could use.

**Heads-up: the course was rebuilt in July 2026.** The older outline (still shown on CoursMooc) had four modules with Generative AI last. The current version moves Generative AI to Module 2, adds AI agents, Agent Builder, Gemini Enterprise and NotebookLM, and moves the Natural Language API lab into Module 3. This guide follows the current order. If the Skills Boost page shows a different order, follow the page and tell me.

## Course at a glance

Five modules, four labs, about 8 hours self-paced and free on [Google Skills](https://www.skills.google/course_templates/593). You've already built the core of two labs, so expect closer to 5 hours.

The course hangs on a three-layer framework. **AI foundations** is infrastructure and data: compute, storage, BigQuery. **AI development** is how a model gets built: pre-trained APIs, AutoML or custom training. **AI solutions** is generative AI and agents built on top of both.

| Module | Topic | Lab | Your status |
| --- | --- | --- | --- |
| 1 | AI Foundations | Predict Visitor Purchases with BigQuery ML | You built this |
| 2 | Generative AI | Get Started with Vertex AI Studio | New to you |
| 3 | AI Development Options | Entity and Sentiment Analysis with Natural Language API | Partly built |
| 4 | AI Development Workflow | Vertex AI: Predict Loan Risk with AutoML | New to you |
| 5 | Course Summary | None | Review only |

Each content module ends with a short quiz.

## Module notes

### Module 1: AI Foundations

Watch first: the AI/ML framework and the infrastructure lesson (compute types, especially GPUs vs. TPUs).

- **You built this: BigQuery ML.** `CREATE MODEL`, `ML.EVALUATE`, `ML.PREDICT`. Your ghost-job model is the same pattern as the lab's purchase model: logistic regression, an imbalanced label, judged on ROC AUC. Yours scored 0.90.
- **You built this: data products.** Cloud Storage as the lake, BigQuery as the warehouse, Pub/Sub and Dataflow for streaming.
- **New to you: model categories.** Supervised learning has labels: classification predicts a class, regression predicts a number. Unsupervised has no labels: clustering, association, dimensionality reduction. Your ghost-job model is supervised classification.
- **New to you: hardware.** CPUs for general work, GPUs for parallel math, TPUs as Google's custom chips for large neural-network training.

### Module 2: Generative AI

Watch all of it. This module is the most changed and the most relevant to Get Connected.

- **New to you: foundation models.** Large models pre-trained on broad data and then adapted. Gemini is multimodal, so it takes text, images, audio, video and code as input.
- **New to you: prompt-to-production lifecycle.** Prototype a prompt in Vertex AI Studio, pick or tune a model, then deploy and monitor it.
- **New to you: prompt design.** Zero-shot, one-shot and few-shot prompting. Also system instructions, and settings like temperature, which controls randomness.
- **New to you: tuning.** Prompt design changes the input. Tuning changes the model with your own examples. Parameter-efficient tuning updates only a small part of the model, so it's cheaper.
- **New to you: Model Garden.** A catalog of Google, open and partner models you can deploy.
- **New to you: AI agents.** An agent wraps a model with goals, tools it can call, memory and a loop that plans steps. Google's tools here are Vertex AI Agent Builder and Gemini Enterprise.
- **Get Connected tie-in:** explainable 1–10 screening is a prompt-design problem. Structured output with a score and a reason field is exactly what the Studio lab practises.

### Module 3: AI Development Options

Watch first: the comparison of the four options. It's the backbone of the cheat sheet below.

- **New to you: the four options.** Pre-trained APIs need no data or ML skill. BigQuery ML needs SQL. AutoML needs your labelled data but no code. Custom training needs code and gives full control.
- **Partly built: Natural Language API.** You tested it in gc-job-intel, then chose a regex skill dictionary instead. New here is how the API scores what it finds. Salience is how central an entity is to the text. Sentiment score runs −1 to +1, and magnitude measures the overall strength of emotion.
- **Get Connected tie-in:** entity analysis tags PERSON entities, which is a route to stripping names in Skills Focus Mode.

### Module 4: AI Development Workflow

Watch all of it.

- **New to you: the three-stage workflow.** Data preparation, model development (train, then evaluate), and model serving (deploy, then monitor).
- **Partly built: evaluation.** You know ROC AUC. New here: precision vs. recall, and the confusion matrix. Precision asks how many flagged items were truly positive. Recall asks how many true positives were caught.
- **New to you: AutoML on Vertex AI.** Upload a tabular dataset and Vertex tries model types and settings for you. The lab does this on loan data.
- **New to you: MLOps.** Treating models like software: versioning, automated retraining, monitoring for drift. Vertex AI Pipelines automates the workflow. Your nightly scheduled query is a small cousin of this idea.

### Module 5: Course Summary

Review only. Use the cheat sheet below instead of rewatching.

## gc-job-intel extensions for Get Connected

Four builds, one per lab, all in the gc-job-intel project on the Kaggle postings. Only what works gets ported to the Replit app. You do the build; I teach and log it.

| # | After lab | Build in gc-job-intel | Get Connected payoff | Cost note |
| --- | --- | --- | --- | --- |
| 1 | Vertex AI Studio (M2) | Gemini prompt that returns JSON skills, seniority and a 1–10 fit score with a reason, for a sample of postings | Prototype of explainable screening and Candidate Passport skill extraction | A few hundred calls on a Flash model cost cents |
| 2 | Natural Language API (M3) | Run the same sample through entity analysis; compare against Gemini and your 39-skill regex | Evidence for which extractor to ship | First 5,000 units a month are free |
| 3 | Natural Language API (M3) | Name-redaction test: detect PERSON entities in resume-style text and mask them | Fixes the Skills Focus Mode name leak | Same free tier; Sensitive Data Protection is the production option |
| 4 | AutoML (M4) | Concepts only: compare AutoML's approach with your hand-built BigQuery ML ghost-job model | Talking point on build-vs-buy ML for mentors and investors | Do NOT train AutoML in your own project; tabular training bills per node-hour. Use the lab sandbox |

Cost figures are approximate; check current Google Cloud pricing before any large run.

Build 1 matters most. Pick 20 postings, hand-label their top skills yourself, and use them as the answer key for builds 1 and 2. That small labelled set is also how you answer "how do you know the screening score is any good?"

## Cheat sheet

Most quiz questions are a scenario that asks which option fits. Match on the clue words.

| Clue in the question | Pick | Why |
| --- | --- | --- |
| No ML expertise, no training data, common task (text, vision, speech, translation) | Pre-trained API | Ready to call |
| Data already in BigQuery, team knows SQL | BigQuery ML | Model where the data lives |
| Own labelled data, little or no code, want a good model fast | AutoML | Vertex picks the model for you |
| Full control of architecture or framework, ML engineers on staff | Custom training | Your code, your choice |
| Generate text, images or code; summarise; chat | Gemini on Vertex AI | Foundation model |
| Test prompts without code | Vertex AI Studio | Prompt playground |
| Browse or deploy third-party and open models | Model Garden | Model catalog |
| Build an agent that uses tools and takes actions | Vertex AI Agent Builder | Agent framework |
| Automate and repeat the ML workflow | Vertex AI Pipelines | MLOps |
| Huge neural-network training | TPUs | Google's custom accelerator |

Likely quiz angles:

- The order of the three layers: foundations, development, solutions.
- Classification vs. regression from a one-line scenario.
- Precision vs. recall: which one matters when false alarms are expensive (precision) or when misses are expensive (recall).
- Prompt design vs. tuning: which one changes the model's weights (tuning).
- What makes something an agent rather than a chatbot: tools and the ability to act.

## Progress tracker

- [x] Module 1 videos + quiz
- [x] Lab: Predict Visitor Purchases with BigQuery ML
- [x] Module 2 videos + quiz
- [x] Lab: Get Started with Agent Studio (formerly Vertex AI Studio), 100/100
- [x] Build 1: Gemini skills extraction and fit score in gc-job-intel
- [x] Hand-label 20 postings as the answer key (done as a recruiter spot-check)
- [x] Module 3 videos + quiz
- [x] Lab: Entity and Sentiment Analysis with Natural Language API, 100/100
- [x] Build 2: NL API vs. Gemini vs. regex comparison
- [x] Build 3: name-redaction test
- [x] Module 4 videos + quiz
- [x] Lab: Agent Platform (formerly Vertex AI): Predicting Loan Risk with AutoML
- [x] Build 4: AutoML vs. BigQuery ML write-up
- [x] Module 5 review (course completed Nov 8, 2026)

## Lab log

### Module 1 lab: Predict Visitor Purchases with BigQuery ML

Completed Nov 6, 2026 in about 25 minutes.

| Step | What you did | Lesson |
| --- | --- | --- |
| Training data | Pulled 10,000 Google Merchandise Store sessions (Aug 2016 – Jun 2017) from date-sharded `ga_sessions_*` tables with `_TABLE_SUFFIX`; saved as the view `bqml_lab.training_data` | A view stores a query, not data. The checker wanted a view, not a table |
| Model | Used Gemini in BigQuery to generate `CREATE MODEL bqml_lab.sample_model`, logistic regression on os, is\_mobile, country, pageviews | Gemini's SQL matched the lab's; always compare before running |
| Prediction data | Built `bqml_lab.july_data`: 74,368 July 2017 sessions plus `fullVisitorId` | Train on the past, predict on a later period |
| Prediction | Fixed the lab's deliberate bug (`TOTAL` is not a BigQuery function; use `SUM`) and ranked countries by predicted purchases | US 98, Taiwan 6, Canada 4, India 2, Turkey 2 |

Key takeaway: only 98 predicted purchases across 74,368 sessions. With no class weights on a rare label, the model mostly predicts "no purchase," so recall is low. Your gc-job-intel ghost-job model used class weights for exactly this reason.

Open item: evaluation metrics (ROC AUC, precision, recall) weren't captured before the lab ended.

### Module 2 lab: Get Started with Agent Studio (GSP1154)

Completed Nov 7, 2026 with a score of 100/100. Vertex AI Studio has been renamed Agent Studio, under Agent Platform in the console.

| Task | What you built | Lesson |
| --- | --- | --- |
| 1. Prompt app | "Insurance Risk Summary - Prototype": system instructions for an underwriting assistant, then SafeHarbor Warehousing and Coastal Goods Delivery scenarios | System instructions carry across every turn and adapt to new domains; the model framed gaps as questions rather than inventing facts |
| 2. Prompt design | "Insurance Claim Data Extraction": fixed field list, "Not found" rule, key: value output; then a one-shot example (John Sterling) before the Eleanor Vance claim | Few-shot teaches style, not just fields: the output copied the example's "(estimate)" flag and "type (detail)" pattern |
| 3. Manage prompts | "Insurance Risk Factor Identification" run in Compare with edited system instructions | Same prompt, different instructions, side by side: an A/B test for prompts |
| 4. Multimodal | "Timetable Image Analysis": Gemini read a flight timetable image and calculated 4 of 13 flights (30.77%) before 11:30, flagging the 11:30 edge case | Gemini can take an image or PDF directly, so resumes don't need text extraction first |
| 5. Media generation | "Honeybee Image Generation" with a Nano Banana image model | Image generation lives in the same Studio, with its own model family |

Lab gotchas worth remembering:

- The lab project allowed only certain models (an `allowedModels` org policy). gemini-4-argon and Nano Banana 2.1 were blocked; gemini-3.8-flash and Nano Banana 2 Lite worked.
- Repeated 429 quota errors. Fixes: region Global, grounding off, wait a minute before one retry.
- The "Example" option in the + menu no longer exists, so the few-shot step was done inline in one message.

Get Connected takeaway: Task 2 is Build 1's blueprint. Fixed fields + "Not found" + fixed format + one worked resume → JSON example, using gemini-3.8-flash.

### Module 3 lab: Entity and Sentiment Analysis with the Natural Language API

Completed Nov 8, 2026 with a score of 100/100, in about 15 minutes.

| Task | What you did | Lesson |
| --- | --- | --- |
| 1. API key | Created a key under APIs & Services → Credentials, restricted to Cloud Natural Language API | The new form requires choosing API restrictions; the Gemini API key button is a different thing |
| 2–3. Entities | Built `request.json` and called `analyzeEntities` with curl from Cloud Shell; uploaded `result.json` to the lab bucket with `gsutil cp` | Entities come back typed (PERSON, WORK\_OF\_ART), linked to Wikipedia, with salience, and with PROPER vs. COMMON mentions |
| 4. Sentiment | Called `analyzeSentiment` on a short book review | Score runs −1 to +1; magnitude is the overall strength of emotion; sentences are scored separately |
| 5. Entity sentiment | Ungraded: `analyzeEntitySentiment` splits a mixed opinion by entity (sushi vs. service) | Per-entity sentiment for reviews and feedback |

Gotchas: there was no lab VM in this version, so Cloud Shell replaced the SSH step. The checker reads the bucket, not your terminal.

Get Connected takeaway: PERSON entities with PROPER mentions are the hook for name redaction in Skills Focus Mode (Build 3); COMMON mentions like "screenwriter" describe the role and stay.

### Module 4 lab: Predicting Loan Risk with AutoML

Completed Nov 8, 2026, in about 20 minutes. This version of the lab has no progress checkpoints.

| Task | What you did | Lesson |
| --- | --- | --- |
| 1. Prepare data | Created tabular dataset LoanRisk from cloud-training/CBL455/LoanRisk.csv (5 columns: age, ClientID, Default, income, loan) | Import, then explore with statistics |
| 2. Train | AutoML classification, target Default, ClientID excluded (4 feature columns), 1 node hour | Drop identifiers; AutoML picks transformations and models |
| 3–4. Evaluate, deploy | Demonstration only: precision/recall curve, confusion matrix, feature importance; endpoints and traffic splitting | Training takes about an hour, so these were read, not run |
| 5. Predict | Called a pre-trained credit-risk model through the AutoML gateway with curl from Cloud Shell | Customer (age \~40, income \~$44,964, loan \~$3,944) scored 0.99999 for class 0 (repays); output matched the expected output |

Gotcha: the JSON block on the lab page is the input file's contents, not a command to paste.

Get Connected takeaway: AutoML is the no-code route to a custom model, but it's slower and costs more to train than BigQuery ML. For gc-job-intel's ghost-job model, BigQuery ML was the right call.

## Build log

### Build 1: Gemini skills extraction in gc-job-intel (complete)

Started Nov 7, 2026. Runs entirely in BigQuery SQL against `jobs_curated` (location us-central1).

| Phase | What you built | Result |
| --- | --- | --- |
| 1. Connect | Connection `gemini_conn` (Cloud Shell `bq mk`), Vertex AI User role for its service account, remote model `jobs_curated.gemini_flash` on gemini-3.8-flash | Smoke test answered from SQL |
| 2. Extract | `build1_sample` (20 postings, fixed with FARM\_FINGERPRINT), `build1_extractions` via ML.GENERATE\_TEXT with a one-shot JSON prompt, `build1_parsed` with skills array, seniority, years | 0 API errors, 0 parse failures, 5.7 skills per posting |
| 2b. Compare | Gemini vs. the 39-skill regex in `posting_skills` | Gemini 114 skill tags, regex 66, both 20 |
| 3. Score | \`build1\_scores\` (fictional data-analyst resume vs. the 20 sample postings) and \`build1\_scores\_analyst\` (vs. 5 real Data Analyst postings); prompt with a bias guard, an anchored 1–10 rubric, and score, reason, matched and missing fields | Wrong roles top out at 4/10 (Enrollment Agent, crediting past customer support, flagging 100% travel); a real Data Analyst posting scores 7/10, with Salesforce as the gap |
| 4. Check | Recruiter spot-check of the 20 v2 extractions in a Google Sheet, plus an automated scan of the descriptions for about 45 common tools and certifications | Recruiter review found no extraction errors; the scan found 1 missed tool (MS Office, Front End Developer) across about 120 hard and domain skills. A spot-check, not a formal benchmark |

Scorer separation (fictional data-analyst resume):

| Test set | Postings | Avg score | Min | Max |
| --- | --- | --- | --- | --- |
| Right roles (Data Analyst titles) | 5 | 4.6 | 3 | 7 |
| Wrong roles (random sample) | 20 | 1.7 | 1 | 4 |

Right roles average 2.7x higher, but the ranges overlap: one Data Analyst posting scored 3. Resolved (confirmed as the right call on recruiter review, Nov 7): the 3 was "Online Data Analyst," which required full professional proficiency in a second language the resume doesn't show. That's a knockout requirement and a misleading title, not an over-strict rubric, so no rubric change. Product idea: show hard requirements (language, license, clearance, travel) as a separate Knockout flag next to the score.

Prompt v2 (`build1_parsed_v2`): skills split into hard, domain and soft buckets. Coverage of the 66 regex tags rose from 20 (30%) with v1 to 34 (52%) with v2. Remaining gaps are likely wording variants and regex false positives; Phase 4 will measure them.

Findings so far:

- Half the postings state no seniority (10 of 20) and nearly half no years of experience (9 of 20).
- Gemini caught skills the dictionary doesn't know (cash handling, GitHub, MS Office) and some it should know (Agile in 2 postings).

Product decision (Nov 7): matching and screening scores use hard and domain skills only. Soft skills (self-motivated, drive, positive attitude and the like) are shown as context, not scored.

Gotchas:

- The Add data UI no longer offers "Connections to external data sources"; `bq mk --connection` in Cloud Shell works.
- Gemini wrapped JSON in markdown fences despite "ONLY valid JSON"; stripped with REGEXP\_REPLACE. Structured output would prevent it.
- `SAFE.JSON_VALUE_ARRAY` isn't supported; use `SAFE.PARSE_JSON` once, then read fields from the JSON value.

### Build 2: NL API vs. Gemini vs. regex (complete)

Completed Nov 8, 2026. A remote model `jobs_curated.nl_api` (REMOTE\_SERVICE\_TYPE = CLOUD\_AI\_NATURAL\_LANGUAGE\_V1) on the same `gemini_conn` connection, with the Service Usage Consumer role. `ML.UNDERSTAND_TEXT` with analyze\_entities over the same 20 postings → `build2_nl_raw`, flattened to `build2_nl_entities`.

| Method | Distinct tags (20 postings) | What it is |
| --- | --- | --- |
| NL API | 2,498 | Every noun phrase, typed as OTHER, PERSON, ORGANIZATION and so on |
| Gemini v2 (hard + domain) | 201 | Skills only, following instructions |
| Regex dictionary | 66 | Fixed list of 39 skills |

- The NL API contained 70 of Gemini's 201 skills (35%) and 26 of the 66 regex skills (39%) as exact strings.
- Only 3.2% of NL API entities matched a known skill; the rest were benefits, company names, places and generic nouns ("nurse residency program", and "Apex Heart & Vascular" filed as OTHER).
- Exact matching undercounts overlap, so treat these as lower bounds.

Verdict: use Gemini for skill extraction. The NL API is a generic entity extractor, cheap (this run fit in the free tier) but noisy, and it would need heavy filtering. Its typed PERSON entities are still useful, which is what Build 3 tests.

### Build 3: name-redaction test (complete)

Completed Nov 8, 2026. A test set `build3_resumes` of 5 fictional resumes with an answer key: 9 personal names to remove (several naming conventions, including family-name-first and accented names) and 16 terms that must survive (tools like Jenkins, Ruby, Julia, Django and Bash; employers like Johnson & Johnson, Ford Motor Company, Walmart and Dell; certifications; a hospital). The NL API kept PERSON entities with PROPER mentions (`build3_nl`); Gemini got explicit do-not-redact rules and returned names plus redacted text (`build3_gemini_raw`). Scored automatically by text containment.

| Tool | Names caught | Must-keep terms wrongly flagged | Redacts emails, phones, URLs |
| --- | --- | --- | --- |
| Gemini (instructed) | 9 of 9 | 0 of 16 | Yes, as \[EMAIL\], \[PHONE\], \[URL\] |
| NL API (PERSON + PROPER) | 8 of 9 (missed Linda Park) | 2 of 16 | No; it only finds entities, and in resume 1 it merged the email into the name |

Verdict: Gemini with explicit rules is the stronger prototype for Skills Focus Mode redaction. Caveats: 5 fictional resumes is a small test, and the match is lenient. Before production, re-test on a larger set, and consider Sensitive Data Protection for emails, phones and IDs.

Gotcha: BigQuery rejects NOT EXISTS with a STRPOS condition ("LEFT ANTISEMI JOIN" error); the workaround is to UNNEST both arrays into pairs and aggregate with LOGICAL\_OR.

### Build 4: AutoML vs. BigQuery ML (write-up, complete)

Completed Nov 8, 2026, as a concepts-only comparison. AutoML training wasn't run in gc-job-intel because it bills per node-hour; the comparison draws on the Module 4 lab and the gc-job-intel ghost-job model.

BigQuery ML is the default for gc-job-intel and Get Connected's tabular models; AutoML is worth it only once the data outgrows what SQL feature engineering and simple models can do.

|  | BigQuery ML (ghost-job model) | AutoML (loan-risk lab) |
| --- | --- | --- |
| Where it runs | Inside BigQuery, in SQL | Agent Platform (Vertex AI), a UI wizard |
| Data movement | None; trains where the data lives | Import into a managed dataset |
| Who picks the model | You (logistic regression, class weights) | AutoML (architecture search, tuning, ensembling) |
| Feature engineering | Manual: days open, apply rate, leak-free company stale rate | Automatic transformations; you choose columns (ClientID excluded) |
| Time to a first model | Minutes | About an hour of training |
| Cost | Query pricing; small runs cost cents | Node-hour training plus endpoint serving |
| Explainability | ML.EVALUATE, feature weights you inspect | Built-in evaluation and feature importance |
| Result in your work | ROC AUC 0.90; riskiest 3% of postings held 58% of stale listings | Didn't finish in the lab; the pre-trained model scored a customer 0.99999 "repays" |

When to move from BigQuery ML to AutoML:

- The data has many columns or messy interactions that hand-built features miss.
- A few points of accuracy are worth paying for, and you have budget for training and serving.
- No one is available to iterate on features and model types in SQL.

Why BigQuery ML wins for now:

- The ghost-job model already reaches ROC AUC 0.90, and its value came from feature engineering (leak-free company stale rate) that AutoML wouldn't invent.
- Iteration happens in minutes, and the nightly scheduled query already serves scores.
- BigQuery ML also has an AutoML-backed model type (AUTOML\_CLASSIFIER), so moving up later doesn't require leaving SQL.

Get Connected takeaway: screening and skills use Gemini (Builds 1–3); structured predictions like ghost-job risk stay in BigQuery ML until there's enough platform data and budget to justify AutoML.

## Sources

Syllabus details from public course pages, read Nov 6, 2026.

- [Introduction to AI and Machine Learning on Google Cloud – Google Skills](https://www.skills.google/course_templates/593)
- [Course outline, updated July 2026 – Global Knowledge (GO9095)](https://www.globalknowledge.com/en-be/courses/google/cloud_computing/go9095/p)
- [Earlier course listing – CoursMooc](https://coursmooc.com/courses/introduction-to-ai-and-machine-learning-on-google-cloud-google-skills-course/)
