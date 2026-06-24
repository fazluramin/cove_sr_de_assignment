# Notes, Assumptions & Data Quality

## Assumptions Made
1. **Raw Data Ingestion:** We assume the raw MongoDB JSONL files have been natively ingested/loaded into BigQuery as baseline tables (`bronze_l0_*`). This dbt project takes over transformation from that point.
2. **Occupancy Math:** The monthly occupancy rate is strictly defined as `Occupied Room Days / Available Room Days`.
3. **Checkout Dates:** A check-out date is considered the day the tenant leaves, meaning that specific night is *not* counted towards occupancy. The inclusive occupancy range is `[check_in_date, check_out_date - 1 day]`.
4. **Deleted Items:** If a room or property has a populated `deletedAt` timestamp, it is considered no longer available for rent on that specific date moving forward.

## Data Quality Issues Noticed
1. **Cancelled Tenancies:** The raw tenancies data contains records with `status: "cancelled"` (e.g., `t_015`). These must be explicitly excluded otherwise they will inflate occupancy rates. 
2. **Date Boundaries:** Some lease start and end dates cross multiple years. Standard `DATE_DIFF` functions fail to accurately bucket overlapping dates into discrete calendar months.

## Edge Cases Handled in the Pipeline
1. **Negative Date Generation:** If a bad data entry causes a `check_out_date` to be equal to or less than a `check_in_date`, the BigQuery `GENERATE_DATE_ARRAY()` function will throw a fatal error. We mitigated this by explicitly filtering `check_in_date < check_out_date` in the silver layer.
2. **Fan-Out on Overlapping Tenancies:** If two active tenancies accidentally overlap on the exact same room on the exact same date, simply joining room availability to tenancies will result in a data "fan-out" (duplicating the room record) and breaking the denominator calculation. We mitigated this by applying a `MAX()` deduplication aggregation per room per calendar day in the gold layer.
3. **Late Deletions:** If an active tenancy technically overlaps with the date a room was marked as `deletedAt`, our pipeline safely ignores the ghost tenancy data because the Gold layer strictly uses a `LEFT JOIN` sourced from the valid available room days timeline.
