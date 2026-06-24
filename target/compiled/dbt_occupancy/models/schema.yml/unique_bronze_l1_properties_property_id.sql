
    
    

with dbt_test__target as (

  select property_id as unique_field
  from `top-alliance-323312`.`cove_dataset`.`bronze_l1_properties`
  where property_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


