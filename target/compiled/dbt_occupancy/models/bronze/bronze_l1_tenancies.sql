with source as (
    select * from `top-alliance-323312`.`cove_dataset`.`bronze_l0_tenancies`
),

renamed as (
    select
        cast(_id as string) as tenancy_id,
        cast(roomId as string) as room_id,
        cast(tenant_id as string) as tenant_id,
        cast(checkInDate as date) as check_in_date,
        cast(checkOutDate as date) as check_out_date,
        cast(status as string) as status,
        cast(updatedAt as timestamp) as updated_at
    from source
)

select * from renamed