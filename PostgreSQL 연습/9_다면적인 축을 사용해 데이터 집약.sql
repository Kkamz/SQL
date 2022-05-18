-- 1.카테고리별 매출과 소계를 동시에 구하는 쿼리
with sub_category_amount as(
	-- 소카테고리의 매출 집계  
	select category as category,
	sub_category as sub_category,
	sum(price) as amount
	from purchase_detail_log2
	group by category, sub_category 
),
category_amount as (
	-- 대 카테고리의 매출 집계 	
	select category,
		'all' as sub_category,
		sum(price) as amount
	from purchase_detail_log2
	group by category 
),
total_amount as (
	-- 전체매출 집계 
	select 'all' as category,
			'all' as sub_category,
			sum(price) as amount
	from purchase_detail_log2
)
select category, sub_category, amount from sub_category_amount
union all select category, sub_category, amount from category_amount
union all select category, sub_category, amount from total_amount

-- 2. ROLLUP을 사용해서 카테고리별 매출과 소계를 동시에 구하는 쿼리 
select coalesce(category,'all') as category,
		coalesce(sub_category,'all') as sub_category,
		sum(price) as amount
from purchase_detail_log2 pdl 
group by rollup(category,sub_category)

-- 3. 매출구성비누계와 ABC등급을 계산하는 쿼리 
--A등급: 상위 0~70% B등급: 상위 70~90% C등급: 상위 90~100%
with monthly_sales as(
	select category,
	-- 항목별 매출 계산하기
	sum(price) as amount
	from purchase_detail_log2 pdl 
	where 
		dt between '2017-01-01' and '2017-01-31'
	group by category 
),
sales_composition_ratio as(
	select category, amount,
	-- 구성비 : 100.0 * <항목별 매출> / <전체매출> 
	100.0 * amount / sum(amount) over() as composition_ratio,
	-- 구성비 누계 : 100.0 * <항목별구계 매출> / <전체매출> 
	100.0 * sum(amount) over(order by amount desc ROWS BETWEEN UNBOUNDED PRECEDING and CURRENT ROW) / SUM(amount) OVER() AS cumulative_ratio
	from monthly_sales
)
select *,
		case when cumulative_ratio between 0 and 70 then 'A'
			when cumulative_ratio between 70 and 90 then 'B'
			when cumulative_ratio between 90 and 100 then 'C'
			end as abc_rank
from sales_composition_ratio
order by amount desc

-- 4. 팬차트 작성 때 필요한 데이터를 구하는 쿼리 
with daily_category_amount as(
	select dt, category,
			substring(dt,1,4) as year,
			substring(dt,6,2) as month,
			substring(dt,9,2) as date,
			sum(price) as amount
	from purchase_detail_log2 pdl 
	group by dt,category 
),
monthly_category_amount as (
	select concat(year,'-',month) as year_month,
			category, sum(amount) as amount
	from daily_category_amount
	group by year_month, category 
)
select 
year_month, category, amount,
first_value(amount) over(partition by category order by year_month, category rows unbounded preceding) as base_amount,
100.0 * amount / first_value(amount) over(partition by category order by year_month, category rows unbounded preceding) as rate
from monthly_category_amount
order by year_month, category 

-- 5. 최댓값, 최솟값, 범위를 구하는 쿼리 
with stats as (
	select -- 금액의 최댓값 
		 	max(price) as max_price,
		 	-- 금액의 최솟값 
		 	min(price) as min_price,
		 	-- 금액의 범위
		 	max(price) - min(price) as range_price,
		 	10 as bucket_num
	from purchase_detail_log2 pdl 
)
select * from stats

-- 6. 데이터의 계층을 구하는 쿼리 
with stats as (
	select -- 금액의 최댓값 
		 	max(price) as max_price,
		 	-- 금액의 최솟값 
		 	min(price) as min_price,
		 	-- 금액의 범위
		 	max(price) - min(price) as range_price,
		 	10 as bucket_num
	from purchase_detail_log2 pdl 
),
purchase_log_with_bucket as (
	select price, min_price,
			price - min_price as diff,
			1.0 * range_price / bucket_num as bucket_range,
			-- 계층판정 : floor(<정규화금액> / <계층범위>)
			--index가 1부터 시작하므로 1만큼 더하
--			floor(1.0*(price-min_price)/(1.0*range_price/bucket_num))+ 1 as bucket
			-- postgresql - width_bucket 사용 가능 
			width_bucket(price,min_price,max_price,bucket_num) as bucket
	from purchase_detail_log2 pdl2, stats
)
select * from purchase_log_with_bucket
order by price

-- 7. 계급상한값을 조정한 쿼리 
with stats as ( 
select 
	-- <금액의 최댓값> + 1
	max(price) + 1 as max_price,
	-- <금액의 최솟값> 
	min(price) as min_price,
	-- <금액의 범위> + 1(실)
	max(price) +1 -min(price) as range_price,
	-- 계층 수 
	10 as bucket_num
from purchase_detail_log2 pdl 
),
purchase_log_with_bucket as (
	select price, min_price,
			price - min_price as diff,
			1.0 * range_price / bucket_num as bucket_range,
			-- 계층판정 : floor(<정규화금액> / <계층범위>)
			--index가 1부터 시작하므로 1만큼 더하
--			floor(1.0*(price-min_price)/(1.0*range_price/bucket_num))+ 1 as bucket
			-- postgresql - width_bucket 사용 가능 
			width_bucket(price,min_price,max_price,bucket_num) as bucket
	from purchase_detail_log2 pdl2, stats
)
select * from purchase_log_with_bucket
order by price

-- 8. 히스토그램을 구하는 쿼리 
with stats as ( 
select 
	-- <금액의 최댓값> + 1
	max(price) + 1 as max_price,
	-- <금액의 최솟값> 
	min(price) as min_price,
	-- <금액의 범위> + 1(실)
	max(price) +1 -min(price) as range_price,
	-- 계층 수 
	10 as bucket_num
from purchase_detail_log2 pdl 
),
purchase_log_with_bucket as (
	select price, min_price,
			price - min_price as diff,
			1.0 * range_price / bucket_num as bucket_range,
			-- 계층판정 : floor(<정규화금액> / <계층범위>)
			--index가 1부터 시작하므로 1만큼 더하
--			floor(1.0*(price-min_price)/(1.0*range_price/bucket_num))+ 1 as bucket
			-- postgresql - width_bucket 사용 가능 
			width_bucket(price,min_price,max_price,bucket_num) as bucket
	from purchase_detail_log2 pdl2, stats
)
select bucket,
		-- 계층의 하한과 상한 계산하기
		min_price + bucket_range * (bucket -1) as lower_limit,
		min_price + bucket_range * bucket as upper_limit,
		-- 도수 세기 
		count(price) as num_purchase,
		-- 합계 금액 계산하기 
		sum(price) as total_amount
from purchase_log_with_bucket
group by bucket, min_price, bucket_range 
order by bucket

-- 9. 히스토그램의 상한과 하한을 수동으로 조정한 쿼리 
with stats as ( 
select 
	-- 금액의 최댓값
	50000 as max_price,
	-- 금액의 최솟값 
	0 as min_price,
	-- 금액의 범위 
	50000 as range_price,
	-- 계층수 
	10 as bucket_num
from purchase_detail_log2 pdl 
),
purchase_log_with_bucket as (
	select price, min_price,
			price - min_price as diff,
			1.0 * range_price / bucket_num as bucket_range,
			-- 계층판정 : floor(<정규화금액> / <계층범위>)
			--index가 1부터 시작하므로 1만큼 더하
--			floor(1.0*(price-min_price)/(1.0*range_price/bucket_num))+ 1 as bucket
			-- postgresql - width_bucket 사용 가능 
			width_bucket(price,min_price,max_price,bucket_num) as bucket
	from purchase_detail_log2 pdl2, stats
)
select bucket,
		-- 계층의 하한과 상한 계산하기
		min_price + bucket_range * (bucket -1) as lower_limit,
		min_price + bucket_range * bucket as upper_limit,
		-- 도수 세기 
		count(price) as num_purchase,
		-- 합계 금액 계산하기 
		sum(price) as total_amount
from purchase_log_with_bucket
group by bucket, min_price, bucket_range 
order by bucket




