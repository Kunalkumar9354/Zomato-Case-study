create schema zomato;
use zomato;

desc delivery_partner;
desc food;
desc menu;
desc order_details;
desc restaurants ;
desc users;
-- 1. Find customers who have never ordered
with not_ordered_table  as
(select u.*,o.order_id
from users u 
left join orders o
on u.user_id = o.user_id)
select user_id ,name,email,password
from not_ordered_table
where order_id is null;
-- 2. Average Price per dish
select f_name as dish,
		round((avg(price)),2) as average_price
from food f
left join menu m
on f.f_id = m.f_id
group by dish;
-- 3. Find the top restaurant in terms of the number of orders for a given month
with top_restaurants as
	(select monthname(o.order_date) as month_name
	,r.r_name,count(distinct o.order_id) as total_orders,
	dense_rank() over(partition by monthname(order_date) order by count(o.order_id) desc) as rnk
	from orders o
	left join restaurants r
	on o.r_id =r.r_id
	group by month_name,r.r_name)
select month_name,r_name ,total_orders
from top_restaurants
where rnk = 1;

-- 4. restaurants with monthly sales greater than 1000 
select  r.r_name,monthname(order_date) as month_name ,sum(amount) as total_amount
from orders o
left join restaurants r
on o.r_id = r.r_id
group by r.r_name,monthname(order_date)
having sum(amount)>1000;
-- 5. Show all orders with order details for a particular customer in a particular date range
select o.user_id,o.order_id,f.f_name,f.type
from orders o
left join 
order_details od 
on o.order_id = od.order_id
left join food f on od.f_id = f.f_id
;
-- 6. Find restaurants with max repeated customers
with most_repeated_customers as 
	(select o.user_id,r.r_name,count(o.user_id) as total_visits,
     dense_rank() over(order by count(o.user_id) desc) as res_rank
	from orders o
	left join restaurants r on o.r_id = r.r_id
	group by o.user_id,r.r_name
    having total_visits>1)
select user_id,r_name,total_visits
from most_repeated_customers
where res_rank =1;

-- 7. Month over month revenue growth of zomato
select monthname(order_date) , sum(amount) as total_amount,
lag(sum(amount)) over() as preivous_month_revenue,
concat((round((100 *((sum(amount)-lag(sum(amount)) over())
/(lag(sum(amount)) over()))),2)),"","%") as revenue_change
from orders
group by monthname(order_date);
-- 8. Customer - favorite food
with most_fav_food as 
	(select u.name,
		f.f_name,
		count(distinct o.order_id) as total_orders,
		rank() over(partition by u.name order by count(distinct o.order_id) desc) as cus_rank
	from orders o
	left join order_details od 
	on o.order_id = od.order_id
	left join food f on od.f_id = f.f_id
	left join users u on o.user_id = u.user_id
	group by u.name,f.f_name
	)
select name,f_name
from most_fav_food
where cus_rank = 1;
-- Find the most loyal customers for all restaurant
with loyal_customer as
		(select r.r_name,u.name,count(distinct o.order_id) as total_orders,
				rank() over(partition by r.r_name order by  count(distinct o.order_id) desc) as customer_rank
		from orders o 
        left join users u on o.user_id = u.user_id
        left join restaurants r on o.r_id = r.r_id
		group by r.r_name,u.name
		)
select r_name,name,total_orders
from loyal_customer
where customer_rank=1;

-- Month over month revenue growth of a restaurant
select r.r_name,monthname(o.order_date) ,
		sum(o.amount) as total_amount,
        lag(sum(o.amount)) over() as previous_sales,
		(sum(o.amount)-lag(sum(o.amount)) over())/lag(sum(o.amount)) over() as revenue_change
from orders o
left join restaurants r
on o.r_id = r.r_id
group by r.r_name,monthname(order_date)
order by r.r_name, monthname(order_date) desc;

