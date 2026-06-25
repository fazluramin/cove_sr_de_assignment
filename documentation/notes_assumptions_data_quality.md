# Notes, Assumptions & Data Quality

## Assumptions Made
1. **Raw Data Ingestion:** I assume the raw MongoDB JSONL files have been natively ingested/loaded into BigQuery as baseline tables (`bronze_l0_*`). This dbt project takes over transformation from that point.
2. **Occupancy Math:** The monthly occupancy rate is strictly defined as `Occupied Room Days / Available Room Days`.
3. **Checkout Dates:** A check-out date is considered the day the tenant leaves, meaning that specific night is *not* counted towards occupancy. The inclusive occupancy range is `[check_in_date, check_out_date - 1 day]`.
4. **Deleted Items:** If a room or property has a populated `deletedAt` timestamp, it is considered no longer available for rent on that specific date moving forward.
5. **Quick Check Validation:** I have included a raw SQL method to quickly validate the total number of available leased days for each room prior to running the daily expansion logic in dbt. Due to SQL's "fencepost" (off-by-one) date math, calculating inclusive calendar days requires a slight adjustment depending on whether the room naturally reached its lease end date (which requires adding 1 day to be inclusive) versus being abruptly terminated by a `deleted_at` flag.

    ```sql
    -- Quick check: Total available room days per room
    SELECT 
        r.room_id, 
        p.lease_start_date, 
        p.lease_end_date, 
        r.deleted_at AS room_deleted_at,
        p.deleted_at AS property_deleted_at, 
        -- Calculate the exact number of physical available days
        DATE_DIFF(
            IFNULL(DATE(COALESCE(r.deleted_at, p.deleted_at)), p.lease_end_date), 
            p.lease_start_date, 
            DAY
        ) + CASE WHEN COALESCE(r.deleted_at, p.deleted_at) IS NULL THEN 1 ELSE 0 END AS total_available_days
    FROM `cove_dataset.bronze_l1_properties` p
    LEFT JOIN `cove_dataset.bronze_l1_rooms` r
        ON p.property_id = r.property_id
    ORDER BY r.room_id;
    ```

## Data Quality Issues Noticed
1. **Cancelled Tenancies:** The raw tenancies data contains records with `status: "cancelled"` (e.g., `t_015`). These must be explicitly excluded otherwise they will inflate occupancy rates. 
2. **Date Boundaries:** Some lease start and end dates cross multiple years. Standard `DATE_DIFF` functions fail to accurately bucket overlapping dates into discrete calendar months.

## Edge Cases Handled in the Pipeline
1. **Negative Date Generation:** If a bad data entry causes a `check_out_date` to be equal to or less than a `check_in_date`, the BigQuery `GENERATE_DATE_ARRAY()` function will throw a fatal error. I mitigated this by explicitly filtering `check_in_date < check_out_date` in the silver layer.
2. **Overlapping Tenancies:** If two active tenancies accidentally overlap on the exact same room on the exact same date, simply joining room availability to tenancies will result in a data duplicating the room record and breaking the calendar explode calculation. I mitigated this by applying a `MAX()` deduplication aggregation per room per calendar day in the gold layer.
3. **Late Deletions:** If an active tenancy technically overlaps with the date a room was marked as `deletedAt`, my pipeline safely ignores the ghost tenancy data because the Gold layer strictly uses a `LEFT JOIN` sourced from the valid available room days timeline.
