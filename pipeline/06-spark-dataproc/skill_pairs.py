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
