-- purpose: identify discrepancies where spot or dedicated customers are using contract booking types,
-- and calculate the distribution of each booking type per customer for monitoring and reporting

-- step 1: count loads per customer per booking type
with booking_type_load_count as
(
    select
        c.customer_id,                       -- unique customer identifier
        c.customer_name,                     -- customer name
        c.customer_type,                     -- type of customer (spot, dedicated, contract)
        l.booking_type,                      -- type of booking for the load
        count(l.load_id) as load_count_per_booking_type  -- number of loads for this booking type
    from customers as c
    left join loads as l
        on c.customer_id = l.customer_id
    group by
        c.customer_id,
        c.customer_name,
        c.customer_type,
        l.booking_type
),

-- step 2: calculate total loads per customer
customer_total_load as
(
    select
        customer_id,
        customer_name,
        customer_type,
        booking_type,
        load_count_per_booking_type,
        sum(load_count_per_booking_type)
            over (partition by customer_id) as total_load_per_customer  -- total loads per customer
    from booking_type_load_count
)

-- step 3: calculate load distribution and flag discrepancies
select
    customer_id,
    customer_name,
    customer_type,
    booking_type,
    load_count_per_booking_type,
    total_load_per_customer,
    round(cast(load_count_per_booking_type as float) / total_load_per_customer * 100, 2) as load_distribution, -- % of total loads
    case
        when customer_type in ('SPOT','DEDICATED') and booking_type = 'CONTRACT' then 'Discrepant Load'  -- flag unusual usage
        else 'OK'  -- everything else is fine
    end as load_flag
from customer_total_load;
