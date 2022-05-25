-- 1. 구매액이 많은 순서로 사용자 그룹을 10등분하는 쿼리 
with user_purchase_amount as (
	select
		user_id,sum(amount) as purchase_amount
	from action_log al 
	where action = 'purchase'
	group by user_id
),
user_with_decile as ( 
	select user_id, purchase_amount, ntile(10) over(order by purchase_amount desc) as decile 
	from user_purchase_amount
)
select * from user_with_decile

-- 2. 10분할한 Decile들 집계하는 쿼리 
with user_purchase_amount as (
	select
		user_id,sum(amount) as purchase_amount
	from action_log al 
	where action = 'purchase'
	group by user_id
),
user_with_decile as ( 
	select user_id, purchase_amount, ntile(10) over(order by purchase_amount desc) as decile 
	from user_purchase_amount
),
decile_with_purchase_amount as (
	select decile,
			sum(purchase_amount) as amount,
			avg(purchase_amount) as avg_amount,
			sum(sum(purchase_amount)) over(order by decile) as cumulative_amount,
			sum(sum(purchase_amount)) over() as total_amount
	from user_with_decile 
	group by decile
)
select * from decile_with_purchase_amount

-- 3. 구매액이 많은 Decile 순서로 구성비와 구성비누계를 계산하는 쿼리 
with user_purchase_amount as (
	select
		user_id,sum(amount) as purchase_amount
	from action_log al 
	where action = 'purchase'
	group by user_id
),
user_with_decile as ( 
	select user_id, purchase_amount, ntile(10) over(order by purchase_amount desc) as decile 
	from user_purchase_amount
),
decile_with_purchase_amount as (
	select decile,
			sum(purchase_amount) as amount,
			avg(purchase_amount) as avg_amount,
			sum(sum(purchase_amount)) over(order by decile) as cumulative_amount,
			sum(sum(purchase_amount)) over() as total_amount
	from user_with_decile 
	group by decile
)
select decile, amount, avg_amount,
		100.0*amount/total_amount as total_ratio,
		100.0*cumulative_amount/total_amount as cumulative_ratio
from decile_with_purchase_amount

-- 4. 사용자별로 RFM을 집계되는 쿼리 
with purcahse_log as ( 
	select user_id, amount,
			substring(stamp,1,10) as dt
	from action_log al 
	where action='purchase'
),
user_rfm as (
	select user_id, max(dt) as recent_date,
		current_date - max(dt::date) as recency,
		count(dt) as frequency,
		sum(amount) as monetary
	from purcahse_log
	group by user_id
)
select * from user_rfm

-- 5. 사용자들의 RFM 랭크를 계산하는 쿼리 
with purcahse_log as ( 
	select user_id, amount,
			substring(stamp,1,10) as dt
	from action_log al 
	where action='purchase'
),
user_rfm as (
	select user_id, max(dt) as recent_date,
		current_date - max(dt::date) as recency,
		count(dt) as frequency,
		sum(amount) as monetary
	from purcahse_log
	group by user_id
),
user_rfm_rank as (
	select user_id, recent_date, recency, frequency, monetary,
			case when recency < 14 then 5
				when recency < 28 then 4
				when recency < 60 then 3
				when recency < 90 then 2
				else 1 end as r,
			case when 20 <= frequency then 5
				when  10 <= frequency then 4
				when 5 <= frequency then 3
				when 2<= frequency then 2
				when 1 = frequency then 1 end as f,
			case when 300000 <= monetary then 5
				when  100000 <= monetary then 4
				when 30000 <= monetary then 3
				when 5000 <= monetary then 2
				else 1 end as m
	from user_rfm
)
select * from user_rfm_rank

-- 6. 각 그룹의 사람 수를 확인하는 쿼리 
with purcahse_log as ( 
	select user_id, amount,
			substring(stamp,1,10) as dt
	from action_log al 
	where action='purchase'
),
user_rfm as (
	select user_id, max(dt) as recent_date,
		current_date - max(dt::date) as recency,
		count(dt) as frequency,
		sum(amount) as monetary
	from purcahse_log
	group by user_id
),
user_rfm_rank as (
	select user_id, recent_date, recency, frequency, monetary,
			case when recency < 14 then 5
				when recency < 28 then 4
				when recency < 60 then 3
				when recency < 90 then 2
				else 1 end as r,
			case when 20 <= frequency then 5
				when  10 <= frequency then 4
				when 5 <= frequency then 3
				when 2<= frequency then 2
				when 1 = frequency then 1 end as f,
			case when 300000 <= monetary then 5
				when  100000 <= monetary then 4
				when 30000 <= monetary then 3
				when 5000 <= monetary then 2
				else 1 end as m
	from user_rfm
),
mst_rfm_index as (
	-- 1 부터 5까지의 숫자를 테이블 만들
	select * from
	generate_series(1,5) as rfm_index
),
rfm_flag as (
	select m.rfm_index, case when m.rfm_index = r.r then 1 else 0 end as r_flag,
						case when m.rfm_index = r.f then 1 else 0 end as f_flag,
						case when m.rfm_index = r.m then 1 else 0 end as m_flag
	from mst_rfm_index as m 
	cross join 
	user_rfm_rank as r 
)
select rfm_index, sum(r_flag) as r, sum(f_flag) as f, sum(m_flag) as m
from rfm_flag
group by 1
order by 1 desc 

-- 7. 통합 랭크를 계산하는 쿼리 
with purcahse_log as ( 
	select user_id, amount,
			substring(stamp,1,10) as dt
	from action_log al 
	where action='purchase'
),
user_rfm as (
	select user_id, max(dt) as recent_date,
		current_date - max(dt::date) as recency,
		count(dt) as frequency,
		sum(amount) as monetary
	from purcahse_log
	group by user_id
),
user_rfm_rank as (
	select user_id, recent_date, recency, frequency, monetary,
			case when recency < 14 then 5
				when recency < 28 then 4
				when recency < 60 then 3
				when recency < 90 then 2
				else 1 end as r,
			case when 20 <= frequency then 5
				when  10 <= frequency then 4
				when 5 <= frequency then 3
				when 2<= frequency then 2
				when 1 = frequency then 1 end as f,
			case when 300000 <= monetary then 5
				when  100000 <= monetary then 4
				when 30000 <= monetary then 3
				when 5000 <= monetary then 2
				else 1 end as m
	from user_rfm
)
select r+f+m as total_rank,
		r,f,m,count(user_id)
from user_rfm_rank
group by r,f,m
order by total_rank desc, r desc, f desc, m desc

-- 8. 종합랭크별로 사용자 수를 집계하는 쿼리 
with purcahse_log as ( 
	select user_id, amount,
			substring(stamp,1,10) as dt
	from action_log al 
	where action='purchase'
),
user_rfm as (
	select user_id, max(dt) as recent_date,
		current_date - max(dt::date) as recency,
		count(dt) as frequency,
		sum(amount) as monetary
	from purcahse_log
	group by user_id
),
user_rfm_rank as (
	select user_id, recent_date, recency, frequency, monetary,
			case when recency < 14 then 5
				when recency < 28 then 4
				when recency < 60 then 3
				when recency < 90 then 2
				else 1 end as r,
			case when 20 <= frequency then 5
				when  10 <= frequency then 4
				when 5 <= frequency then 3
				when 2<= frequency then 2
				when 1 = frequency then 1 end as f,
			case when 300000 <= monetary then 5
				when  100000 <= monetary then 4
				when 30000 <= monetary then 3
				when 5000 <= monetary then 2
				else 1 end as m
	from user_rfm
)
select r+f+m as total_rank, count(user_id)
from user_rfm_rank
group by 1
order by 1 desc

-- 9. R과 F를 사용해 2차원 사용자 층의 사용자 수를 집계하는 쿼리 
with purcahse_log as ( 
	select user_id, amount,
			substring(stamp,1,10) as dt
	from action_log al 
	where action='purchase'
),
user_rfm as (
	select user_id, max(dt) as recent_date,
		current_date - max(dt::date) as recency,
		count(dt) as frequency,
		sum(amount) as monetary
	from purcahse_log
	group by user_id
),
user_rfm_rank as (
	select user_id, recent_date, recency, frequency, monetary,
			case when recency < 14 then 5
				when recency < 28 then 4
				when recency < 60 then 3
				when recency < 90 then 2
				else 1 end as r,
			case when 20 <= frequency then 5
				when  10 <= frequency then 4
				when 5 <= frequency then 3
				when 2<= frequency then 2
				when 1 = frequency then 1 end as f,
			case when 300000 <= monetary then 5
				when  100000 <= monetary then 4
				when 30000 <= monetary then 3
				when 5000 <= monetary then 2
				else 1 end as m
	from user_rfm
)
select concat('r_',r) as rank,
		count(case when f = 5 then 1 end) as f_5,
		count(case when f = 4 then 1 end) as f_4,
		count(case when f = 3 then 1 end) as f_3,
		count(case when f = 2 then 1 end) as f_2,
		count(case when f = 1 then 1 end) as f_1
from user_rfm_rank
group by r
order by 1 desc