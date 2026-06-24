# Setup & Run Instructions

## Prerequisites
1. **Python 3.x** installed locally.
2. A **Google Cloud / BigQuery** account with a valid Service Account JSON key.
3. Raw data ingested into a BigQuery dataset named `cove_dataset` as `bronze_l0_properties`, `bronze_l0_rooms`, and `bronze_l0_tenancies`.

## 1. Environment Setup
Create a virtual environment and install `dbt-bigquery`:

```bash
python3 -m venv venv
source venv/bin/activate
pip install dbt-bigquery
```

## 2. Authentication Configuration
Place your Google Cloud Service Account JSON key into the `service_account/` directory.

The `profiles.yml` file in the root directory is already configured to point to the `cove_dataset` in BigQuery using this service account:

```yaml
dbt_occupancy:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: [YOUR_PROJECT_ID]
      dataset: cove_dataset
      threads: 4
      keyfile: service_account/[YOUR_KEY_FILE].json
      location: asia-southeast2
```

## 3. Running the Pipeline
To execute the pipeline and build the tables natively in BigQuery, run:

```bash
dbt run --full-refresh --profiles-dir .
```

*The `--full-refresh` flag ensures that any existing tables/views are dropped and recreated cleanly.*

## 4. Testing
We have defined basic `not_null` and `unique` primary key tests in the `models/schema.yml`. To execute them:

```bash
dbt test --profiles-dir .
```
