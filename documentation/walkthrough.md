# Step-by-Step Guide & Approach

## The Problem
Calculating monthly occupancy rates (`Occupied Days / Available Days`) is complex when tenancies and property leases span across multiple months. It is difficult to accurately assign portions of a single lease to different calendar months using standard `DATE_DIFF` logic without writing overly complex SQL logic.

## Our Approach: The Daily Explosion (Calendar Spine)
To solve this, we applied a daily expansion strategy in the **Silver layer**. By reducing all date ranges down to their lowest common denominator (the individual day), aggregating them into calendar months becomes trivial.

### 0. Pre-Bronze (Raw Data Ingestion)
The raw MongoDB exports were natively ingested into BigQuery.

![GCS Dump Mongo Src](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/GCS_Dump_mongo_src_raw.png)
![BQ Bronze L0 Properties](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/BQ_bronze_l0_properties.png)
![BQ Bronze L0 Rooms](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/BQ_bronze_l0_rooms.png)
![BQ Bronze L0 Tenancies](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/BQ_bronze_l0_tenancies.png)

### 1. Bronze Layer (Staging)
* **Models:** `bronze_l1_properties`, `bronze_l1_rooms`, `bronze_l1_tenancies`
* **Purpose:** Acts as a 1:1 reflection of the raw `cove_dataset` tables. We apply native BigQuery type casting (strings to dates/timestamps) and rename columns to standardize the naming convention (snake_case).

![BQ Bronze L1 Properties](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/BQ_bronze_l1_properties.png)
![BQ Bronze L1 Rooms](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/BQ_bronze_l1_rooms.png)
![BQ Bronze L1 Tenancies](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/BQ_bronze_l1_tenancies.png)

### 2. Silver Layer (Cleaned & Conformed)
* **Models:** `silver_rooms_daily_status`, `silver_tenancies_daily_occupancy`
* **Purpose:** Explodes the data. 
    - **Rooms Daily Status:** We use BigQuery's `GENERATE_DATE_ARRAY` to generate a master calendar spanning the earliest to latest property lease dates. We `CROSS JOIN` this with our rooms, keeping only the days where the property lease is active and the room/property hasn't been deleted.
    - **Tenancies Daily Occupancy:** For all active tenancies, we explode the duration between `check_in_date` and the day *before* `check_out_date` into individual days.

![BQ Silver Rooms](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/BQ_silver_rooms_daily_status.png)
![BQ Silver Tenancies](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/BQ_silver_tenancies_daily_occupancy.png)

### 3. Gold Layer (Business Marts)
* **Models:** `gold_monthly_property_occupancy`
* **Purpose:** Final Aggregation. We `LEFT JOIN` the generated available room days to the occupied tenancy days. We deduplicate any overlapping edge cases, group by the property and calendar month, and simply count the total days.
    - `total_available_room_days`: Total physical room days existing in that month.
    - `total_occupied_room_days`: Total room days successfully joined to an active tenancy.
    - `occupancy_rate`: `total_occupied_room_days / total_available_room_days`.

![BQ Gold Monthly Occupancy](/Users/fazlur.amin/Documents/GIT/cove_sr_de_assignment/documentation/BQ_gold_monthly_property_occupancy.png)
