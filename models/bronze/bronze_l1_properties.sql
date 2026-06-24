with source as (
    select * from {{ source('cove_dataset', 'bronze_l0_properties') }}
),

renamed as (
    select
        cast(_id as string) as property_id,
        cast(name as string) as property_name,
        cast(city as string) as city,
        cast(lease_start_date as date) as lease_start_date,
        cast(lease_end_date as date) as lease_end_date,
        cast(updatedAt as timestamp) as updated_at,
        cast(deletedAt as timestamp) as deleted_at
    from source
)

select * from renamed
