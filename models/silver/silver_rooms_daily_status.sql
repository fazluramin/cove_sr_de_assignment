with properties as (
    select * from {{ ref('bronze_l1_properties') }}
),

rooms as (
    select * from {{ ref('bronze_l1_rooms') }}
),
-- Generate a date array as helper to expand each lease period from lease_start to lease_end into daily records
calendar as (
    select date_array
    from unnest(
        generate_date_array(
            (select min(lease_start_date) from properties),
            (select max(lease_end_date) from properties),
            interval 1 day
        )
    ) as date_array
),
-- Cross join rooms with date array, then filter to their active period
room_days as (
    select
        c.date_array as calendar_date,
        r.room_id,
        r.property_id,
        r.room_number,
        r.room_type,
        p.property_name,
        p.city
    from rooms r
    join properties p on r.property_id = p.property_id
    cross join calendar c
    where
        c.date_array >= p.lease_start_date and c.date_array <= p.lease_end_date -- Property lease active on this date
        and (p.deleted_at is null or c.date_array < date(p.deleted_at)) -- Property not deleted, or deleted after this date
        and (r.deleted_at is null or c.date_array < date(r.deleted_at)) -- Room not deleted, or deleted after this date
)

select * from room_days
