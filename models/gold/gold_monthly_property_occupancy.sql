with room_days as (
    select * from {{ ref('silver_rooms_daily_status') }}
),

tenancy_days as (
    select * from {{ ref('silver_tenancies_daily_occupancy') }}
),

daily_status as (
    select
        r.calendar_date,
        date_trunc(r.calendar_date, month) as calendar_month,
        r.property_id,
        r.property_name,
        r.city,
        r.room_id,
        max(case when t.room_id is not null then 1 else 0 end) as is_occupied
    from room_days r
    left join tenancy_days t 
        on r.room_id = t.room_id 
        and r.calendar_date = t.occupied_date
    group by 1, 2, 3, 4, 5, 6
),

monthly_occupancy as (
    select
        calendar_month,
        property_id,
        property_name,
        city,
        count(room_id) as total_available_room_days,
        sum(is_occupied) as total_occupied_room_days,
        safe_divide(sum(is_occupied), count(room_id)) as occupancy_rate
    from daily_status
    group by 1, 2, 3, 4
)

select * from monthly_occupancy
order by property_name, calendar_month
