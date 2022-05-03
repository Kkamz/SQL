-- 1. 날짜별 매출과 평균 구매액을 집계하는 쿼리 
select dt, count(*) as purchase_cnt,
		sum(purchase_amount) as total_amount,
		avg(purchase_amount) as avg_amount 
from purchase_log2 p
group by 1
order by 1

-- 2. 날짜별 매출과 7일 이동편균을 집계하는 쿼리 
select dt,sum(purchase_amount) as total_amount,
		-- 최근 최대 7일 동안의 평균 계산 
		avg(sum(purchase_amount)) over(order by dt rows between 6 preceding and current row) as seven_day_avg,
		-- 최근 7일 동안의 평균 확실하게 계산 
		case when 7 = count(*) over(order by dt rows between 6 preceding and current row)
			then avg(sum(purchase_amount)) over(order by dt rows between 6 preceding and current row)
			end as seven_day_avg_strict
from purchase_log2 pl 
group by 1
order by 1

-- 3. 날짜별 매출과 당월 누계 매출을 집계하는 쿼리 
select dt,
	-- substring 사용해  연-월 추출 
	substring(dt,1,7) as year_month,
	-- substr 활용
	substr(dt,1,7) as year_month2,
	sum(purchase_amount) as total_amount,
	sum(sum(purchase_amount)) over(partition by substring(dt,1,7) order by dt rows unbounded preceding) as agg_amonut
from purchase_log2
group by dt
order by 1

-- 4. 날짜별 매출을 일시 테이블로 만드는 쿼리 
with daily_purchase as (
	select dt,
			-- 연, 월, 일 각각 추출 
			substring(dt,1,4) as year,
			substring(dt,6,2) as month,
			substring(dt,9,2) as date,
			sum(purchase_amount) as purchase_amount,
			count(order_id) as orders
	from purchase_log2
	group by dt
)
select *
from daily_purchase
order by dt

-- 5. daily_purchase 테이블에 대해 당월 누계 매출을 집계하는 쿼리 
with daily_purchase as (
	select dt,
			-- 연, 월, 일 각각 추출 
			substring(dt,1,4) as year,
			substring(dt,6,2) as month,
			substring(dt,9,2) as date,
			sum(purchase_amount) as purchase_amount,
			count(order_id) as orders
	from purchase_log2
	group by dt
)
select dt,
		concat(year,'-',month) as year_month,
		purchase_amount,
		sum(purchase_amount) over(partition by substring(dt,1,7) order by dt rows unbounded preceding) as agg_amonut
from daily_purchase
order by 1

-- 6. 월별 매출과 작대비를 계산하는 쿼리  
with daily_purchase as (
	select dt,
			-- 연, 월, 일 각각 추출 
			substring(dt,1,4) as year,
			substring(dt,6,2) as month,
			substring(dt,9,2) as date,
			sum(purchase_amount) as purchase_amount,
			count(order_id) as orders
	from purchase_log3
	group by dt
)
select month,
		sum(case year when '2014' then purchase_amount end) as amount_2014,
		sum(case year when '2015' then purchase_amount end) as amount_2015,
		100.0 * sum(case year when '2014' then purchase_amount end)/sum(case year when '2015' then purchase_amount end) as rate 
from daily_purchase 
group by 1
order by 1

-- 7. 2015년 매출에 대한 z차트를 작성하는 쿼리 
with daily_purchase as (
	select dt,
			-- 연, 월, 일 각각 추출 
			substring(dt,1,4) as year,
			substring(dt,6,2) as month,
			substring(dt,9,2) as date,
			sum(purchase_amount) as purchase_amount,
			count(order_id) as orders
	from purchase_log3
	group by dt
),
monthly_amount as (
	select year, month,sum(purchase_amount) as amount
	from daily_purchase
	group by 1,2
),
calc_index as ( 
	select year,month,amount,
			-- 당월부터 11개월 이전까지 총 12개월 같의 매출 합계(이동 년계) 집계하
			sum(case when year='2015' then amount end) over(order by year,month rows unbounded preceding) as agg_amount,
			sum(amount) over(order by year,month rows between 11 preceding and current row) as year_avg_amount
	from monthly_amount
	order by 1,2
)
-- 2015년의 데이터만 압축하기 
select concat(year,'-',month) as year_month, amount,
		agg_amount,year_avg_amount
from calc_index
where year='2015'
order by year_month

-- 8. 매출과 관련된 지표를 집계하는 쿼리 
with daily_purchase as (
	select dt,
			-- 연, 월, 일 각각 추출 
			substring(dt,1,4) as year,
			substring(dt,6,2) as month,
			substring(dt,9,2) as date,
			sum(purchase_amount) as purchase_amount,
			count(order_id) as orders
	from purchase_log3
	group by dt
),
monthly_purchase as (
	select year, month,
			sum(orders) as orders,
			avg(purchase_amount) as avg_amount,
			sum(purchase_amount) as monthly
	from daily_purchase
	group by 1,2
)
select concat(year,'-',month) as year_month, orders,
		avg_amount, monthly, sum(monthly) over(partition by year order by month rows unbounded preceding) as agg_amount,
		-- 12개월 전의 매출 구하기 
		LAG(monthly, 12) over(order by year,month) as last_year,
		100.0 * monthly / LAG(monthly, 12) over(order by year,month) as rate
from monthly_purchase
order by 1