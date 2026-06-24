with source as (
    select * from {{ source('cove_dataset', 'bronze_l0_rooms') }}
),

renamed as (
    select
        cast(_id as string) as room_id,
        cast(propertyId as string) as property_id,
        cast(room_number as string) as room_number,
        cast(type as string) as room_type,
        cast(updatedAt as timestamp) as updated_at,
        cast(deletedAt as timestamp) as deleted_at
    from source
)

select * from renamed
