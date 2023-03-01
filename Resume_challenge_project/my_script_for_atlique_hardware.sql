use gdb023

/* 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region. */

Select distinct market 
from dim_customer 
where customer = 'Atliq Exclusive' and region = 'APAC'

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? */
 
with t1 as
	(select count(distinct product_code) as 'unique_products_2020'
    from fact_sales_monthly
	where fiscal_year = 2020),
t2 as
	(select count(distinct product_code) as 'unique_products_2021' 
    from fact_sales_monthly
	where fiscal_year = 2021)
select unique_products_2020,
	   unique_products_2021,
       Round( 100 *(unique_products_2021-unique_products_2020) /unique_products_2020,2)  from t1,t2

/* 3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts */

select segment,count(product_code) as product_count from dim_product
group by 1
order by 2 desc

/* 4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020 */

with t1 as
	(select segment,count( distinct product_code) as 'product_count_2020'
	from fact_sales_monthly join dim_product using(product_code)
	where fiscal_year = 2020
	group by 1
	order by 2 desc),
t2 as
	(select segment,
			count( distinct product_code) as 'product_count_2021'
	from fact_sales_monthly 
						join dim_product using(product_code)
	where fiscal_year = 2021
	group by 1
	order by 2 desc)
select t1.segment,
	   product_count_2020 , 
       product_count_2021 ,
	   product_count_2021 -product_count_2020 as difference from t1 
join t2 using (segment)
order by 4 desc

 /* 5. Get the products that have the highest and lowest manufacturing costs */

with t1 as
	(select product_code , 
			Round(manufacturing_cost,2) as manufacturing_cost 
    from fact_manufacturing_cost
	where manufacturing_cost =   (select  max(manufacturing_cost) from fact_manufacturing_cost) 
	union 
	select product_code , 
			Round(manufacturing_cost,2) as manufacturing_cost  
	from fact_manufacturing_cost
	where manufacturing_cost =   (select  min(manufacturing_cost) from fact_manufacturing_cost))
select t1.product_code , 
	   product,manufacturing_cost   
from t1 
	  join dim_product using(product_code)
order by 3 desc

/* 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct
 for the fiscal year 2021 and in the Indian market. */

select customer_code,
	   customer,
	   Round(avg(pre_invoice_discount_pct) ,4) as average_discount,
       concat(Round(avg(pre_invoice_discount_pct) * 100,2),'%') as average_discount_percentage
from dim_customer 
				join fact_pre_invoice_deductions using(customer_code)
where market = 'India' and fiscal_year = 2021
group by 1,2 
order by 3 desc 
limit 5


/* 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
This analysis helps to get an idea of low and high-performing months and take strategic decisions. */

select  Extract(month from date) as month,
		Extract(year from date) as year,
		concat(round(sum(sold_quantity * gross_price)/1000000,2),' M') as gross_sales_amount 
from fact_sales_monthly 
				join dim_customer using( customer_code) 
				join fact_gross_price using(product_code ,fiscal_year) 
where customer = 'Atliq Exclusive' 
group by 1,2

/* 8. In which quarter of 2020, got the maximum total_sold_quantity? */

select concat('Q',Extract(quarter from adddate(date, interval 4 month))) as Quarter ,
	   concat(round(sum(sold_quantity) / 1000000,2),' M') as total_sold_quantity 
from fact_sales_monthly
where fiscal_year = 2020
group by 1
order by 2 desc

/* 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? */

with t1 as 
	(select channel,
    Round(sum(sold_quantity * gross_price)/1000000,2) as gross_sales_mln
	from fact_sales_monthly 
					join fact_gross_price using(product_code ,fiscal_year)
					join dim_customer using(customer_code)
	where fact_sales_monthly.fiscal_year = 2021
	group by channel
	order by 2 desc)
select channel ,
	   gross_sales_mln,
	   concat(round(100*(gross_sales_mln / (select sum(gross_sales_mln) from t1)),2),'%') as percentage 
from t1

/* 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? */
with cte as
	(select division,
			product_code,
            product,
			sum(sold_quantity) as total_sold_quantity,
            dense_rank() over(partition by division order by sum(sold_quantity) desc) as rank_order
	from fact_sales_monthly join dim_product using(product_code)
	where fiscal_year = 2021
	group by 1,2,3)
select * from cte
where rank_order <= 3











 


	





