
    
    

with dbt_test__target as (

  select tenancy_id as unique_field
  from `top-alliance-323312`.`cove_dataset`.`bronze_l1_tenancies`
  where tenancy_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


