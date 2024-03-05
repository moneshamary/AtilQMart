--  TASK-1 : List of products with base price greater than 500 and featured in promotype BOGOF(Buy One Get One Free)
Select distinct(p.product_name),f.base_price
	from fact_events f 
		join dim_products p
			on f.product_code=p.product_code
				where f.base_price>500 and f.promo_type="BOGOF";
                
                
-- TASK-2 : Count of number of stores in each city
Select city,count(store_id) as store_count 
	from dim_stores 
		group by city 
			order by store_count desc;


-- TASK-3 : Total revenue before and after for each campaign
with cte1 as(
select *,
case
	when promo_type="50% OFF" then base_price*0.5
    when promo_type="25% OFF" then base_price*0.75
    when promo_type="33% OFF" then base_price*0.67
    when promo_type="BOGOF" then base_price*0.5
    when promo_type="500 Cashback" then (base_price-500)
end as promo_price,
case
	when promo_type="BOGOF" then `quantity_sold(after_promo)`*2
    else `quantity_sold(after_promo)`
end as after_promo_qty
from fact_events
)
,cte2 as 
(
select c.campaign_name,ROUND(SUM(base_price*`quantity_sold(before_promo)`/1000000),2) as `Total_revenue_(before_promo)`,
ROUND(SUM(promo_price*after_promo_qty/1000000),2) as `Total_revenue_(after_promo)`
from cte1 c1 join dim_campaigns c on c1.campaign_id=c.campaign_id group by c.campaign_name
)
select * from cte2;


-- TASK-4 : Incremental Sold Quantity(ISU%) for each category during Diwali campaign
with cte1 as (
    Select
        p.category,
        SUM(f.`quantity_sold(before_promo)`) as Total_sold_before_promo,
        SUM(f.`quantity_sold(after_promo)`) as total_sold_after_promo,
        Case
            when f.promo_type = "BOGOF" then
                (((SUM(f.`quantity_sold(after_promo)`) * 2) - SUM(f.`quantity_sold(before_promo)`)) / SUM(f.`quantity_sold(before_promo)`)) * 100
            else
                ((SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`)) / SUM(f.`quantity_sold(before_promo)`)) * 100
        end as  `Incremental_sold_quantity_(isu%)`
    from
        fact_events f 
    join
        dim_products p on f.product_code = p.product_code 
    where
        f.campaign_id = "CAMP_DIW_01" 
    group by 
        p.category,f.campaign_id
)
Select
    category,`Incremental_sold_quantity_(isu%)`,
    rank() over (order by `Incremental_sold_quantity_(isu%)` desc) as rank_order 
from
    cte1 ;
    
-- TASK-5 : Top 5 products ranked by Incremental Revenue(IR%) across all campaigns
with cte1 as (
    Select *,
Case
	when promo_type = "50% OFF" then base_price*0.5
	when promo_type = "25% OFF" then base_price*0.75
	when promo_type = "33% OFF" then 0.67 * base_price
	when promo_type = "BOGOF" then base_price*0.5
	when promo_type ='500 Cashback' then (base_price - 500)
end as promo_price
,case
	when promo_type="BOGOF" then `quantity_sold(after_promo)`*2
    else `quantity_sold(after_promo)`
end as after_promo_qty 
        from fact_events
),cte2 as (
select dp.product_name,dp.category,
SUM(base_price * `quantity_sold(before_promo)` / 1000000) as total_revenue_bef_promo_mn,
SUM(after_promo_qty*promo_price/1000000) as total_revenue_aft_promo_mn
    from 
        cte1  join 
        dim_products dp on cte1.product_code = dp.product_code group by product_name,category
        order by total_revenue_aft_promo_mn desc
)
Select
    product_name,category
    ,ROUND((total_revenue_aft_promo_mn-total_revenue_bef_promo_mn) / (total_revenue_bef_promo_mn)*100,2) as `Incremental_Revenue(ir%)`
from
    cte2
order by 
    `Incremental_Revenue(ir%)` desc
limit 5;
