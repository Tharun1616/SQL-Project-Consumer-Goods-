
-- Question 1
-- Provide the list of markets in which customer "Atliq Exclusive" 
-- operates its business in the APAC region.

select market
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC';

-- Question 2
-- What is the percentage of unique product increase in 2021 vs. 2020?

with cte1 as (
	select count(distinct product_code) unique_products_2020
	from fact_sales_monthly
	where fiscal_year = 2020
),
cte2 as (
	select count(distinct product_code) unique_products_2021
	from fact_sales_monthly
	where fiscal_year = 2021
)
select *, 
		(cte2.unique_products_2021-cte1.unique_products_2020)*100/cte1.unique_products_2020 as percentage_chg
from cte1,cte2;

-- Question 3
-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts.

select segment,count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

-- Question 4
-- Which segment had the most increase in unique products in 2021 vs 2020?

with cte1 as (
	select dp.segment,count(distinct dp.product_code) as product_count_2020
	from fact_sales_monthly fs
	join dim_product dp
	on dp.product_code = fs.product_code
	where fs.fiscal_year = 2020
	group by dp.segment
),
cte2 as (
	select dp.segment,count(distinct dp.product_code) as product_count_2021
	from fact_sales_monthly fs
	join dim_product dp
	on dp.product_code = fs.product_code
	where fs.fiscal_year = 2021
	group by dp.segment
)
select cte1.segment,
		cte1.product_count_2020,
        cte2.product_count_2021,
		(cte2.product_count_2021 - cte1.product_count_2020) as difference
from cte1
join cte2
using (segment)
order by difference desc;

-- Question 5
-- Get the products that have the highest and lowest manufacturing costs.

select product_code,
		product,manufacturing_cost
from fact_manufacturing_cost fm
join dim_product dp 
using (product_code)
where manufacturing_cost = ( select max(manufacturing_cost) from fact_manufacturing_cost )
or manufacturing_cost = ( select min(manufacturing_cost) from fact_manufacturing_cost );

-- Question 6
-- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market

select fpr.customer_code,
		dc.customer,
		round(avg(fpr.pre_invoice_discount_pct),3) as average_discount_percentage
FROM fact_pre_invoice_deductions fpr
join dim_customer dc
using (customer_code)
where fiscal_year = 2021 and market = 'India'
group by fpr.customer_code,dc.customer
order by average_discount_percentage desc
limit 5;


-- Question 7
-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.

select monthname(fs.date) as month, Year(fs.date) as year,
        round(sum(fs.sold_quantity * fg.gross_price)/1000000,2) as gross_sales_mln
from fact_sales_monthly fs
join fact_gross_price fg
using (product_code,fiscal_year)
join dim_customer dc
using (customer_code)
where dc.customer = 'Atliq Exclusive'
group by month,year
order by year;

-- Question 8
-- In which quarter of 2020, got the maximum total_sold_quantity?

select 
	case
		when month(date) in (9,10,11) then 'Q1'
        when month(date) in (12,1,2) then 'Q2'
        when month(date) in (3,4,5) then 'Q3'
        else 'Q4'
	end as quarter,
    sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by quarter
order by total_sold_quantity desc;

-- Question 9
-- Which channel helped to bring more gross sales in the fiscal 
-- year 2021 and the percentage of contribution

with cte1 as(
	select dc.channel,
			round(sum(fs.sold_quantity * fg.gross_price)/1000000,2) as gross_sales_mln
	from fact_sales_monthly fs
	join fact_gross_price fg
	using (product_code,fiscal_year)
	join dim_customer dc
	using (customer_code)
	where fs.fiscal_year = 2021
    group by channel
)
select *,
		round(gross_sales_mln*100/sum(gross_sales_mln) over(),2) as pct
from cte1
order by gross_sales_mln desc;

-- Question 10
-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021

with cte1 as (
	select dp.division,fs.product_code,
			dp.product, sum(fs.sold_quantity) as total_sold_quantity
	from fact_sales_monthly fs
	join dim_product dp
	using (product_code)
	where fiscal_year = 2021
	group by dp.division, fs.product_code, dp.product
),
cte2 as (
	select *,
			Dense_rank() over(partition by division order by total_sold_quantity desc) as rank_order
	from cte1
)
select * from cte2
where rank_order <= 3