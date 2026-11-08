# Kaggle SQL Study Notes

Nov 5, 2026 · @Sunny

## How to use these notes

These notes cover all 10 lessons of Kaggle's [Intro to SQL](https://www.kaggle.com/learn/intro-to-sql) and [Advanced SQL](https://www.kaggle.com/learn/advanced-sql), one section per lesson, in BigQuery SQL. Read the section before the lesson, then do the exercise notebook and apply it in gc-job-intel. The course pages didn't render their lesson text when fetched, so the notes follow the courses' known structure; check them against the lessons as you go.

| Day | Lessons | Est. time |
| --- | --- | --- |
| Fri, Nov 6 | Intro L1, L2 | 1 hr |
| Sat, Nov 7 | Intro L3, L4 | 1.5 hr |
| Sun, Nov 8 | Intro L5, L6 + certificate | 1.5 hr |
| Mon, Nov 9 | Advanced L1 | 1 hr |
| Tue, Nov 10 | Advanced L2 | 1.5 hr |
| Wed, Nov 11 | Advanced L3 | 1 hr |
| Thu, Nov 12 | Advanced L4 + certificate + capstone | 1 hr |

- [ ] Intro to SQL certificate
- [ ] Advanced SQL certificate
- [ ] Capstone query in gc-job-intel (CTE + join + window function)

## Intro L1: Getting Started With SQL and BigQuery

BigQuery organizes data as project → dataset → table, and the first job is always to look at a table's schema before querying it.

- **Project**: a container for datasets (Kaggle uses `bigquery-public-data`).
- **Dataset**: a collection of tables, like a database.
- **Table**: rows and columns; each column has a name, type and mode.

In a Kaggle notebook you explore through the Python client:

```python
from google.cloud import bigquery
client = bigquery.Client()

dataset_ref = client.dataset("hacker_news", project="bigquery-public-data")
dataset = client.get_dataset(dataset_ref)
print([t.table_id for t in client.list_tables(dataset)])

table = client.get_table(dataset_ref.table("full"))
print(table.schema)                                       # columns, types, modes
client.list_rows(table, max_results=5).to_dataframe()     # preview rows for free
```

**Schema fields to read:** `name`, `field_type` (STRING, INTEGER, TIMESTAMP…), `mode` (NULLABLE, REQUIRED, REPEATED), `description`.

**Remember:** `list_rows` previews a table without running a query, so it costs no scan budget.

**In gc-job-intel:** in the BigQuery console, open a public dataset, read its Schema and Preview tabs, then do the same for any table you load.

### Tutorial walkthrough (Hacker News dataset)

The tutorial explores the `hacker_news` dataset in six steps. Each step builds on the one before, so run them in order.

1. **Import and connect.** `from google.cloud import bigquery`, then `client = bigquery.Client()`. The client is the object every other command goes through.
2. **Point at a dataset.** `dataset_ref = client.dataset("hacker_news", project="bigquery-public-data")` builds a reference (an address). It doesn't fetch anything yet.
3. **Fetch the dataset.** `dataset = client.get_dataset(dataset_ref)` makes an API call and returns the dataset object.
4. **List its tables.** `tables = list(client.list_tables(dataset))`, then loop and `print(table.table_id)`. Hacker News has several tables; the tutorial focuses on one of them, `full`.
5. **Fetch one table and read its schema.** `table = client.get_table(dataset_ref.table("full"))`, then `table.schema`. Each column is a `SchemaField` with a name, a type (STRING, INTEGER, TIMESTAMP…), a mode (NULLABLE, REQUIRED, REPEATED) and a description.
6. **Preview rows.** `client.list_rows(table, max_results=5).to_dataframe()` shows the first rows as a pandas table. Add `selected_fields=table.schema[:1]` to preview only some columns.

**Mental model:** project → dataset → table works like building → filing cabinet → folder. A *reference* is an address; `get_*` actually goes and fetches the thing.

```latex
\text{project} \rightarrow \text{dataset} \rightarrow \text{table} \rightarrow \text{columns (schema)}
```

### My exercise work (Chicago Crime), Nov 6, 2026

| Question | Code I used | Answer |
| --- | --- | --- |
| 1. How many tables? | `list(client.list_tables(dataset))`, print each `table_id` | 1 (`crime`) |
| 2. How many TIMESTAMP columns in `crime`? | Loop over `table.schema`, print `field.name, field.field_type` | 2 (`date`, `updated_on`) |
| 3. Which columns plot crimes on a map? | Same schema printout | `['latitude', 'longitude']` (`x_coordinate`/`y_coordinate` also work) |

**Mistakes I hit and fixes:**

- **Pasted code into the middle of a comment line** → `SyntaxError`. Fix: Ctrl+A, Delete, then paste into an empty cell.
- **Wrote `[latitude, longitude]` without quotes** → `NameError: name 'latitude' is not defined`. Fix: text values need quotes, `['latitude', 'longitude']`. Same rule in SQL: `WHERE country = 'US'`.
- **Pink `SyntaxWarning` after the setup cell** is from Kaggle's grader, not my code. Safe to ignore; wait for "Setup Complete."

## Intro L2: SELECT, FROM & WHERE

Every query picks columns (SELECT), from a table (FROM), and filters rows (WHERE).

```sql
SELECT city, country
FROM `bigquery-public-data.openaq.global_air_quality`
WHERE country = 'US'
```

- Table names use backticks: `` `project.dataset.table` ``.
- Strings use single quotes; `=` for equality, `!=` or `<>` for not equal.
- Combine filters with `AND` / `OR`; use `IN ('US', 'CA')`, `LIKE '%data%'`, `IS NULL`.
- `SELECT DISTINCT country` returns unique values.

Running it from Python:

```python
query_job = client.query(query)
df = query_job.to_dataframe()
```

**Control cost (important):** BigQuery bills by bytes scanned, not rows returned.

```python
# Estimate before running
dry = client.query(query, job_config=bigquery.QueryJobConfig(dry_run=True))
print(dry.total_bytes_processed)

# Hard cap: query fails instead of scanning more than ~10 MB
safe = bigquery.QueryJobConfig(maximum_bytes_billed=10**7)
client.query(query, job_config=safe)
```

**Remember:** `SELECT *` scans every column. Name only the columns you need.

**In gc-job-intel:** set a `maximum_bytes_billed` cap on your own project's queries from day one.

### Tutorial walkthrough (OpenAQ air quality)

The tutorial writes the first real SQL queries against `openaq.global_air_quality`, a table of pollution readings by city.

1. **SELECT … FROM** picks one or more columns from a table: `SELECT city FROM table`.
2. **WHERE** keeps only rows that meet a condition: `WHERE country = 'US'`.
3. **SELECT \*** returns every column; select several columns by separating them with commas.
4. **Run it from Python** in four steps (below), which every later lesson reuses.
5. **Watch the cost.** A dry run estimates bytes scanned before running, and `maximum_bytes_billed` cancels a query that would scan more than the limit.

**The four-step pattern in every exercise:**

| Step | Code | What it does |
| --- | --- | --- |
| 1. Write | `my_query = """SELECT … FROM … WHERE …"""` | The SQL, as a text string |
| 2. Send | `query_job = client.query(my_query, job_config=safe_config)` | Sends it to BigQuery |
| 3. Collect | `results = query_job.to_dataframe()` | Pulls the answer into a pandas table |
| 4. Show | `print(results.head())` | Shows the first 5 rows |

### My exercise work (OpenAQ), Nov 6, 2026

| Question | My query | Result |
| --- | --- | --- |
| 1. Which countries report in ppm? | `SELECT country FROM ... WHERE unit = 'ppm'` | Correct (e.g., AR, CO). Countries repeat; `SELECT DISTINCT country` lists each once |
| 2. Which readings are exactly 0? | `SELECT * FROM ... WHERE value = 0` | Correct (first rows were from Poland) |

**Mistakes I hit and fixes:**

- **Duplicated `first_query = first_query =`** from pasting. Python ran it, but keep one assignment per line.
- **Left the `____` blank in the run step** → `AttributeError: 'PlaceholderValue' object has no attribute 'head'`. Fix: `zero_pollution_results = query_job.to_dataframe()`.
- **Pasted on top of old code** → broken lines and duplicates. Fix: click inside the box first so the cursor blinks, then Ctrl+A, Delete, paste.
- **Quotes rule:** text values get quotes (`'ppm'`), numbers don't (`0`).

## Intro L3: GROUP BY, HAVING & COUNT

GROUP BY collapses rows into one row per group, an aggregate function summarizes each group, and HAVING filters the groups.

```sql
SELECT parent, COUNT(id) AS num_replies
FROM `bigquery-public-data.hacker_news.full`
GROUP BY parent
HAVING COUNT(id) > 10
```

- Aggregates: `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`; `COUNT(DISTINCT x)` for unique values.
- `COUNT(1)` or `COUNT(*)` counts rows; `COUNT(col)` skips NULLs in that column.
- **WHERE vs HAVING:** WHERE filters rows before grouping; HAVING filters groups after aggregating.

**Rule:** every column in SELECT must either be in GROUP BY or be inside an aggregate. Breaking it is the most common error in this lesson.

**Remember:** alias aggregates with `AS` (`num_replies`) so the output is readable and you can reference it later.

**In gc-job-intel:** count postings per company and keep only companies with more than N postings.

### Tutorial walkthrough (Hacker News comments)

The tutorial answers "which comments got the most replies?" by grouping comments on their `parent` and counting.

1. **COUNT()** returns how many rows there are. `COUNT(1)` counts every row regardless of NULLs.
2. **GROUP BY** splits rows into groups that share a value (all comments with the same parent), and COUNT then runs once per group.
3. **HAVING** filters groups after counting: `HAVING COUNT(1) > 10` keeps only parents with more than 10 replies.
4. **AS (alias)** names the output column: `COUNT(1) AS NumPosts`. Without it, BigQuery invents a name like `f0_`.

**Order of operations:** FROM picks the table → WHERE filters rows → GROUP BY groups them → COUNT summarizes each group → HAVING filters the groups.

### My exercise work (Hacker News), Nov 6, 2026

| Question | My query | Result |
| --- | --- | --- |
| 1. Authors with more than 10,000 posts | ``SELECT `by` AS author, COUNT(1) AS NumPosts FROM ... GROUP BY author HAVING COUNT(1) > 10000`` | Correct |
| 2. How many comments were deleted? | `SELECT COUNT(1) AS num_deleted_posts FROM ... WHERE deleted = True` | 0 in the current table; grader accepted 0 |

**Mistakes I hit and fixes:**

- **Used a column that doesn't exist (`author`)** → `BadRequest: Unrecognized name`. The column is called `by`. Fix: check Schema/Preview for exact names first.
- **Column named after a SQL keyword** (`by`) must be wrapped in backticks: `` `by` ``.
- **Pasted inside a comment line again** → `IndentationError: unexpected indent`. Fix: delete the leftover comment text so each line starts cleanly. Before pasting, check that Ctrl+A highlighted everything in blue.
- **Typed a placeholder number** instead of the real result. Always copy the number the query printed.
- **No GROUP BY needed for a single total.** `COUNT(1)` with only WHERE returns one number.

## Intro L4: ORDER BY and dates

ORDER BY sorts the result (ascending by default, `DESC` for descending), and EXTRACT pulls parts out of dates.

```sql
SELECT COUNT(consecutive_number) AS num_accidents,
       EXTRACT(DAYOFWEEK FROM timestamp_of_crash) AS day_of_week
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
GROUP BY day_of_week
ORDER BY num_accidents DESC
```

- Types: `DATE` (2026-11-05), `DATETIME` (date + time, no zone), `TIMESTAMP` (absolute moment, UTC).
- `EXTRACT(part FROM col)`: YEAR, MONTH, DAY, DAYOFWEEK (1 = Sunday), WEEK, HOUR.
- Other handy ones: `DATE(ts)`, `DATE_TRUNC(d, MONTH)`, `DATE_DIFF(d1, d2, DAY)`.
- Clause order is fixed: SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT.

**Remember:** add `LIMIT` when you only want the top rows; it shortens output but does **not** reduce bytes scanned.

**In gc-job-intel:** postings per month with `DATE_TRUNC(posted_date, MONTH)`, newest first.

### Tutorial walkthrough (US traffic fatalities)

The tutorial uses the NHTSA traffic-fatality data to answer "which day of the week has the most fatal accidents?"

1. **ORDER BY** sorts results, ascending (A→Z, small→large) by default.
2. **DESC** reverses the order, largest first.
3. **Dates:** `DATE` holds a calendar day; `TIMESTAMP` adds the time of day.
4. **EXTRACT** pulls one part out of a date: `EXTRACT(DAYOFWEEK FROM timestamp_of_crash)` returns 1–7 (Sunday = 1). Other parts: DAY, WEEK, MONTH, YEAR.
5. **Putting it together:** count accidents, GROUP BY the extracted day of week, ORDER BY the count DESC.

### My exercise work (World Bank education data), Nov 6, 2026

Columns: `country_name`, `country_code`, `indicator_name`, `indicator_code`, `value`, `year`. Each row is one statistic for one country in one year; `indicator_code` says which statistic.

| Question | My query | Result |
| --- | --- | --- |
| 1. Average education spending (% of GDP) by country, 2010–2017, highest first | `SELECT country_name, AVG(value) AS avg_ed_spending_pct ... WHERE indicator_code = 'SE.XPD.TOTL.GD.ZS' AND year >= 2010 AND year <= 2017 GROUP BY country_name ORDER BY avg_ed_spending_pct DESC` | Correct |
| 2. Indicator codes with at least 175 rows in 2016, most frequent first | `SELECT indicator_code, indicator_name, COUNT(1) AS num_rows ... WHERE year = 2016 GROUP BY indicator_code, indicator_name HAVING COUNT(1) >= 175 ORDER BY COUNT(1) DESC` | Correct (top: population growth and total population, 232 rows each) |

**Takeaways:**

- **Check column names first.** I previewed the table before writing any query this time.
- **Combine filters with AND** inside one WHERE.
- **Every non-aggregated column in SELECT goes in GROUP BY**, so both `indicator_code` and `indicator_name` are grouped.
- **"At least 175" means `>=`**, not `>`.
- **Full clause order:** SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY.

## Intro L5: AS & WITH (CTEs)

A CTE (common table expression) is a named, temporary result you define with WITH and then query like a table, which breaks a hard query into readable steps.

```sql
WITH time AS (
  SELECT DATE(block_timestamp) AS trans_date
  FROM `bigquery-public-data.crypto_bitcoin.transactions`
)
SELECT COUNT(1) AS transactions, trans_date
FROM time
GROUP BY trans_date
ORDER BY trans_date
```

- `AS` renames a column or table (alias).
- Chain several CTEs with commas: `WITH a AS (...), b AS (SELECT ... FROM a)`.
- A CTE exists only inside the query that defines it; it isn't saved anywhere.

**Remember:** CTEs make queries readable; they don't make them cheaper. BigQuery still scans what the CTE reads.

**In gc-job-intel:** step 1 CTE cleans raw postings (dedupe, parse dates), step 2 aggregates. This is the shape most of your pipeline queries will take.

### Tutorial walkthrough (Bitcoin transactions)

The tutorial counts Bitcoin transactions per day using a CTE.

1. **AS** gives a column (or table) a new name: `DATE(block_timestamp) AS trans_date`.
2. **WITH name AS ( … )** defines a temporary table (CTE) that exists only for this query.
3. **The main query reads from the CTE** like a normal table: `SELECT … FROM time GROUP BY trans_date`.
4. **Why bother:** splitting "prepare the data" from "analyze the data" keeps big queries readable.

### My exercise work (Chicago Taxi Trips), Nov 6, 2026

| Question | My query | Result |
| --- | --- | --- |
| 1. Find the table name | `list(client.list_tables(dataset))` | `'taxi_trips'`, correct |
| 2. Peek at the data | `client.list_rows(table, max_results=5).to_dataframe()` | Some location fields are None/NaN, a data-quality issue |
| 3. Trips per year | `SELECT EXTRACT(YEAR FROM trip_start_timestamp) AS year, COUNT(1) AS num_trips ... GROUP BY year ORDER BY year` | Correct; data runs through 2023 |
| 4. Trips per month in 2016 | Same, with `MONTH` and `WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2016` | Correct |
| 5. Trips and avg speed by hour (Q1 2016) | CTE `RelevantRides` filters dates and drops zero-second/zero-mile trips; main query computes `COUNT(1) AS num_trips` and `3600 * SUM(trip_miles) / SUM(trip_seconds) AS avg_mph` per `hour_of_day` | Correct |

**What the data showed (Q5):** taxis are fastest around 5 AM (\~33 mph, few trips) and slowest at evening rush, 5 PM (\~14.6 mph, \~394k trips).

**My first CTE:**

```sql
WITH RelevantRides AS (
  SELECT EXTRACT(HOUR FROM trip_start_timestamp) AS hour_of_day, trip_miles, trip_seconds
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_start_timestamp > '2016-01-01' AND trip_start_timestamp < '2016-04-01'
    AND trip_seconds > 0 AND trip_miles > 0
)
SELECT hour_of_day, COUNT(1) AS num_trips,
       3600 * SUM(trip_miles) / SUM(trip_seconds) AS avg_mph
FROM RelevantRides
GROUP BY hour_of_day
ORDER BY hour_of_day
```

**Mistakes I hit and fixes:**

- **Code pasted inside a comment line again.** Quick fix: click right before the code and press Enter to move it onto its own line.
- **Template placeholders like `(...)` and `.to_dataframe()` with nothing before the dot** must be fully replaced: `client.query(speeds_query, job_config=safe_config)` and `speeds_query_job.to_dataframe()`.
- **Extra closing parenthesis** left over from the template. Every `(` needs exactly one `)`; click a bracket to see its highlighted partner.

## Intro L6: Joining Data

A JOIN combines rows from two tables on a matching key; INNER JOIN keeps only rows that match in both.

```sql
SELECT L.license, COUNT(1) AS number_of_files
FROM `bigquery-public-data.github_repos.sample_files` AS sf
INNER JOIN `bigquery-public-data.github_repos.licenses` AS L
  ON sf.repo_name = L.repo_name
GROUP BY L.license
ORDER BY number_of_files DESC
```

- Alias each table (`sf`, `L`) and prefix columns with it to avoid ambiguity.
- The `ON` clause names the key; check both columns have the same type and meaning.
- Before joining, ask: is the key unique on one side (one-to-many) or on neither (many-to-many, which multiplies rows)?

**Remember:** if a join's row count looks too big, you probably joined on a non-unique key.

**In gc-job-intel:** join postings to a companies table on `company_id` to add industry or size.

### Tutorial walkthrough (pets and owners)

The tutorial joins a `pets` table to an `owners` table to list each pet with its owner's name.

1. **A JOIN combines two tables** using a column they share (the key).
2. **Alias each table** with `AS`: `pets AS p`, `owners AS o`. Then prefix columns: `p.Name`, `o.Name`.
3. **ON says how rows match:** `ON p.ID = o.Pet_ID`.
4. **INNER JOIN** keeps only rows that match in both tables. (Advanced SQL covers the other join types.)

### My exercise work (Stack Overflow), Nov 6, 2026

Key insight: `posts_answers.parent_id` = `posts_questions.id`. Each answer points to the question it answers.

| Question | My query | Result |
| --- | --- | --- |
| 1. List the tables | `[table.table_id for table in client.list_tables(dataset)]` (a list comprehension) | Correct |
| 2. Review `posts_answers` | Previewed rows; found `parent_id` | Join key identified |
| 3. Questions tagged "bigquery" | `SELECT id, title, owner_user_id FROM posts_questions WHERE tags LIKE '%bigquery%'` | Correct |
| 4. Answers to those questions | `SELECT a.id, a.body, a.owner_user_id FROM posts_questions AS q INNER JOIN posts_answers AS a ON q.id = a.parent_id WHERE q.tags LIKE '%bigquery%'` | Correct |
| 5. BigQuery experts: answers per user | Same join + `SELECT a.owner_user_id AS user_id, COUNT(1) AS number_of_answers ... GROUP BY a.owner_user_id` | Correct |

**My first expert-finder query:**

```sql
SELECT a.owner_user_id AS user_id, COUNT(1) AS number_of_answers
FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
INNER JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON q.id = a.parent_id
WHERE q.tags LIKE '%bigquery%'
GROUP BY a.owner_user_id
```

**Takeaways:**

- **LIKE with `%`** matches text that *contains* a word: `'%bigquery%'` also catches `google-bigquery` and `bigquery-sql`.
- **Find the join key before writing the join** by previewing both tables.
- **Join + GROUP BY + COUNT** = "how much activity per person on a topic." The same shape ranks candidates by demonstrated skill for Get Connected AI.
- **Paste trick:** click at the end of a template line, press Shift+Home to select it, then paste over it.

## Advanced L1: JOINs and UNIONs

JOINs combine tables side by side (more columns); UNIONs stack them top to bottom (more rows).

| Join | Keeps |
| --- | --- |
| INNER JOIN | Only rows that match in both tables |
| LEFT JOIN | All rows from the left table; NULLs where the right has no match |
| RIGHT JOIN | All rows from the right table |
| FULL JOIN | All rows from both; NULLs on whichever side has no match |

```sql
-- Questions with or without answers
SELECT q.id AS q_id, MIN(TIMESTAMP_DIFF(a.creation_date, q.creation_date, SECOND)) AS time_to_answer
FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
  ON q.id = a.parent_id
GROUP BY q_id
```

```sql
SELECT owner_user_id FROM questions_2019
UNION DISTINCT          -- removes duplicates
SELECT owner_user_id FROM answers_2019
```

- UNION requires the same number of columns with matching types, in the same order.
- `UNION ALL` keeps duplicates; `UNION DISTINCT` removes them. BigQuery makes you pick one.

**Remember:** use LEFT JOIN when "no match" is itself information (questions never answered). Filter `WHERE a.id IS NULL` to find exactly those.

**In gc-job-intel:** UNION ALL postings from different sources into one table, then LEFT JOIN to find postings with no matching company record.

### Tutorial walkthrough (Hacker News stories and comments)

The tutorial joins stories to their comments and shows how each join type treats rows with no match.

1. **INNER JOIN** keeps only matching rows, so stories with zero comments disappear.
2. **LEFT JOIN** keeps every story; stories with no comments get NULL in the comment columns.
3. **RIGHT and FULL JOIN** keep all rows from the right table, or from both.
4. **UNION ALL / UNION DISTINCT** stack query results vertically. Both SELECTs need the same number of columns with matching types.

### My exercise work (Stack Overflow), Nov 6, 2026

| Question | Fix / query | Result |
| --- | --- | --- |
| 1. Time for questions to get answers (Jan 2018) | Original INNER JOIN showed 100% answered and only 134,719 questions, because unanswered questions were dropped. Changed to **LEFT JOIN** | Correct |
| 2. First question and answer dates per user (Jan 2019) | Filled the blank with **FULL JOIN**: keep users who only asked or only answered | Correct |
| 3. Users who joined Jan 2019, first question and first answer | `users AS u LEFT JOIN posts_answers AS a ON u.id = a.owner_user_id LEFT JOIN posts_questions AS q ON u.id = q.owner_user_id`, `MIN()` of each date, filter on `u.creation_date`, `GROUP BY id` | Correct |
| 4. Distinct users who posted on Jan 1, 2019 | Question IDs `UNION DISTINCT` answer IDs, each filtered with `EXTRACT(DATE FROM creation_date) = '2019-01-01'` | Done |

**Takeaways:**

- **Choose the join by asking "whose rows must never disappear?"** Questions → LEFT; both sides → FULL; only matches → INNER.
- **Put the table you're listing on the left** (users, questions, companies) and LEFT JOIN activity onto it.
- **Suspicious numbers reveal join bugs:** 100% answered and too few rows meant INNER JOIN was silently dropping data.
- **Three-table joins** chain one JOIN after another, each with its own ON.
- **UNION DISTINCT** removes duplicates, **UNION ALL** keeps them. The project will use UNION ALL to combine postings from multiple sources.

## Advanced L2: Analytic (window) functions

Analytic functions compute a value over a window of related rows but, unlike GROUP BY, keep every row in the output.

```sql
SELECT taxi_id, trip_start_timestamp,
       ROW_NUMBER() OVER (PARTITION BY taxi_id ORDER BY trip_start_timestamp) AS trip_number,
       LAG(trip_end_timestamp) OVER (PARTITION BY taxi_id ORDER BY trip_start_timestamp) AS prev_trip_end
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE DATE(trip_start_timestamp) = '2013-10-03'
```

The OVER clause has three parts:

1. `PARTITION BY` splits rows into groups (one window per taxi).
2. `ORDER BY` sets the order inside each group.
3. Window frame (optional) picks which rows count, e.g. `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` for a 7-day moving average.

| Kind | Functions | Use |
| --- | --- | --- |
| Aggregate | `SUM`, `AVG`, `COUNT`, `MIN`, `MAX` | Running totals, moving averages |
| Navigation | `LAG`, `LEAD`, `FIRST_VALUE`, `LAST_VALUE` | Previous/next row, time between events |
| Numbering | `ROW_NUMBER`, `RANK`, `DENSE_RANK` | Ordering, top-N per group, dedup |

**Remember:** `ROW_NUMBER` gives 1,2,3 even on ties; `RANK` gives 1,1,3; `DENSE_RANK` gives 1,1,2.

**Dedup pattern (you'll use this constantly):**

```sql
SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY job_url ORDER BY scraped_at DESC) AS rn
  FROM postings
) WHERE rn = 1
```

**In gc-job-intel:** a 7-day moving average of new postings, and each company's month-over-month change with LAG.

### Tutorial walkthrough (San Francisco bike trips)

The tutorial uses window functions to compute running totals and per-bike sequences of trips.

1. **A window function** computes a value over related rows but keeps every row (unlike GROUP BY, which collapses them).
2. **OVER ( … )** defines the window: PARTITION BY (groups), ORDER BY (order within each group), and an optional frame (`ROWS BETWEEN …`).
3. **Three families:** aggregate (AVG, SUM, COUNT), navigation (LAG, LEAD, FIRST\_VALUE, LAST\_VALUE) and numbering (ROW\_NUMBER, RANK, DENSE\_RANK).

### My exercise work (Chicago Taxi Trips), Nov 6, 2026

| Question | My answer | Result |
| --- | --- | --- |
| 1. 7-day rolling average of daily trips (Q1 2016) | `AVG(num_trips) OVER (ORDER BY trip_date ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING) AS avg_num_trips` on a `trips_by_day` CTE | Correct (after removing a duplicate `AS avg_num_trips`) |
| 2. Number trips within each pickup area | `RANK() OVER (PARTITION BY pickup_community_area ORDER BY trip_start_timestamp) AS trip_number` | Done |
| 3. Minutes of break before each trip | `TIMESTAMP_DIFF(trip_start_timestamp, LAG(trip_end_timestamp) OVER (PARTITION BY taxi_id ORDER BY trip_start_timestamp), MINUTE) AS prev_break` | Matches Kaggle's solution exactly; grader said "Incorrect" because `trip_end_timestamp` is now empty (NaT) for that date, a dataset/grader mismatch |

**Takeaways:**

- **No PARTITION BY** = one window across all rows (a single timeline). **With PARTITION BY**, numbering and LAG restart for each group.
- **ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING** = a centered 7-row window. At the edges it simply uses the rows that exist.
- **RANK** gives ties the same number (1, 1, 3); **ROW\_NUMBER** never ties (1, 2, 3).
- **LAG(x)** = x from the previous row (default offset 1); the first row in each partition gets NULL.
- **When the grader disagrees, compare with the official solution.** If they match, it's the data, not you.
- **Project uses:** 7-day moving average of new postings; `ROW_NUMBER() ... WHERE rn = 1` to dedupe reposts; LAG on `posted_date` per company and title to detect repeated reposting (a ghost-job signal).

## Advanced L3: Nested and repeated data

BigQuery stores nested data as STRUCTs (a column with sub-fields) and repeated data as ARRAYs (a column with many values per row); you read structs with dot notation and flatten arrays with UNNEST.

| Schema mode | Type | Example | How to query |
| --- | --- | --- | --- |
| Nested | `RECORD` / STRUCT | `device.browser` | `SELECT device.browser` |
| Repeated | `REPEATED` / ARRAY | `language` = \[Python, SQL\] | `CROSS JOIN UNNEST(language)` |
| Both | `REPEATED RECORD` | `hits` with `hits.page.pagePath` | `UNNEST(hits) AS h` then `h.page.pagePath` |

```sql
-- Count repos by language (language is a REPEATED RECORD)
SELECT l.name AS language_name, COUNT(*) AS num_repos
FROM `bigquery-public-data.github_repos.languages`,
     UNNEST(language) AS l
GROUP BY language_name
ORDER BY num_repos DESC
```

- The comma before `UNNEST` is shorthand for `CROSS JOIN UNNEST(...)`: one output row per array element.
- Rows with an empty array disappear in a cross join; use `LEFT JOIN UNNEST(arr) AS x` to keep them.
- `ARRAY_LENGTH(arr)` counts elements without unnesting.

**Remember:** in the schema, `mode = REPEATED` means array and `field_type = RECORD` means struct.

**In gc-job-intel:** load each posting with `skills` as an ARRAY, then UNNEST it to count the most-requested skills per role.

### Tutorial walkthrough (pets and Google Analytics)

The tutorial shows how BigQuery stores data that doesn't fit a flat table.

1. **Nested (STRUCT / RECORD):** one column holds several sub-fields. Read them with a dot, e.g. `committer.name`, `committer.date`.
2. **Repeated (ARRAY):** one cell holds a list of values.
3. **Repeated record:** a list of structs, e.g. `language` = \[{name, bytes}, …\].
4. **UNNEST(array) AS x** flattens a list into rows: one output row per element, with the parent row's other columns repeated.

### My exercise work (GitHub Repos), Nov 6, 2026

| Question | My query | Result |
| --- | --- | --- |
| 1. Most commits per person in 2016 | `SELECT committer.name AS committer_name, COUNT(*) AS num_commits FROM github_repos.sample_commits WHERE committer.date >= '2016-01-01' AND committer.date < '2017-01-01' GROUP BY committer_name ORDER BY num_commits DESC` | Done |
| 2. Rows after UNNEST of the sample table | Count one row per language in each repo's list, then add them up | `num_rows = 6` |
| 3. Most popular languages by repo count | `SELECT l.name AS language_name, COUNT(*) AS num_repos FROM github_repos.languages, UNNEST(language) AS l GROUP BY language_name ORDER BY num_repos DESC` | Done |
| 4. Languages in `polyrabbit/polyglot`, by size | `SELECT l.name, l.bytes FROM github_repos.languages, UNNEST(language) AS l WHERE repo_name = 'polyrabbit/polyglot' ORDER BY l.bytes DESC` | Done |

**Takeaways:**

- **Dot notation reads nested fields;** no join needed.
- **The comma before UNNEST** pairs each row with its own list (a correlated cross join).
- **After UNNEST, counting rows per element counts parents:** each repo contributes one row per language, so `COUNT(*)` per language = repos using it.
- **To list one parent's elements,** filter with WHERE instead of grouping.
- **Project use:** store `skills` as an ARRAY per posting, then `UNNEST(skills) AS s ... GROUP BY s` gives the most-requested skills, overall or per role.

## Advanced L4: Writing efficient queries

In BigQuery, cost and speed come mostly from bytes scanned and rows shuffled, so efficient queries read fewer columns, less data, and avoid exploding joins.

The lesson measures with two helpers: one shows bytes scanned (via a dry run, as in L2) and one times a query. Compare before and after each change.

1. **Select only the columns you need.** BigQuery is columnar, so `SELECT *` reads every column; naming 3 columns can cut the scan by 90%+.
2. **Read less data.** Filter early, and filter on partitioned or clustered columns (often a date) so BigQuery skips whole chunks.
3. **Avoid many-to-many joins.** Joining on a non-unique key on both sides multiplies rows. Aggregate or dedupe first (often in a CTE), then join.

**Remember:** `LIMIT` does not reduce bytes scanned; only fewer columns or partition filters do.

**In gc-job-intel:** partition your postings table by `posted_date` and cluster by `company_id`, then compare the bytes scanned with and without a date filter.

### Tutorial walkthrough (efficiency strategies)

The tutorial measures queries with helpers that print the data scanned and the run time, then compares a slow and a fast version of each.

1. **Select only the columns you want.** BigQuery stores data by column, so fewer columns means fewer bytes read.
2. **Read less data.** Filter early and use the narrowest table or partition that answers the question.
3. **Avoid N:N joins.** Joining on keys that repeat on both sides multiplies rows; aggregate first, then join.

### My exercise work, Nov 6, 2026

| Question | My answer | Why |
| --- | --- | --- |
| 1. Which query benefits most from optimization? | `3`, the GPS costume-location query | Runs constantly, on a table that grows by a row per costume per second, with users waiting on the result |
| Remaining questions | Completed; Advanced SQL certificate earned | — |

**Takeaways:**

- **Optimize what runs often or powers a product,** not one-off analysis.
- **For gc-job-intel:** queries behind the Looker Studio dashboard re-run on every view, so those get partition filters (`posted_date`), named columns and pre-aggregated `jobs_curated` tables.

## Courses completed

- **Intro to SQL:** certificate earned Nov 6, 2026
- **Advanced SQL:** certificate earned Nov 6, 2026

## Cheat sheet + common gotchas

One query shape covers almost everything in both courses:

```sql
WITH cleaned AS (                         -- L5: CTE
  SELECT p.*, c.industry
  FROM postings AS p                      -- L1/L2
  LEFT JOIN companies AS c                -- L6 / Adv L1
    ON p.company_id = c.company_id
  WHERE p.posted_date >= '2026-01-01'     -- L2 + Adv L4: filter early
)
SELECT industry,
       DATE_TRUNC(posted_date, MONTH) AS month,           -- L4
       COUNT(*) AS postings,                               -- L3
       SUM(COUNT(*)) OVER (PARTITION BY industry
                           ORDER BY DATE_TRUNC(posted_date, MONTH)) AS running_total  -- Adv L2
FROM cleaned
GROUP BY industry, month
HAVING COUNT(*) > 5                                        -- L3
ORDER BY industry, month                                   -- L4
```

| Gotcha | Fix |
| --- | --- |
| "SELECT list expression references column which is neither grouped nor aggregated" | Add the column to GROUP BY or wrap it in an aggregate |
| Table name error | Wrap the full path in backticks: `` `project.dataset.table` `` |
| Using an alias in WHERE | WHERE runs before SELECT; repeat the expression or filter in an outer query/CTE |
| Row count exploded after a join | Key isn't unique; dedupe or aggregate before joining |
| Rows vanished after UNNEST | Empty arrays drop in a cross join; use `LEFT JOIN UNNEST(...)` |
| UNION error | Must say `UNION ALL` or `UNION DISTINCT`; column counts/types must match |
| Query too expensive | Name columns, filter on the partition column, set `maximum_bytes_billed` |
