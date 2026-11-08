-- 04 – Create the curated postings table (saved as `04_create_curated_postings`)
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
