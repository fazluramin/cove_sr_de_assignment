with tenancies as (
    select * from {{ ref('bronze_l1_tenancies') }}
    where status = 'active'
      and check_in_date < check_out_date
),

tenancy_days as (
    select
        t.tenancy_id,
        t.room_id,
        t.tenant_id,
        occupied_date
    from tenancies t
    cross join unnest(
        generate_date_array(
            t.check_in_date,
            date_sub(t.check_out_date, interval 1 day)
        )
    ) as occupied_date
)

select * from tenancy_days
