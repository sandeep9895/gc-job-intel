# Build 4: AutoML vs. BigQuery ML (write-up, complete)

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

