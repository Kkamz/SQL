-- 1. 연령별 구분과 카테고리를 집계하는 쿼리 
with mst_users_with_int_birth_date as (
	select *,
	-- 특정날짜(2022-05-20)의 정수표현 
	20220520 as int_specific_date,
	cast(replace(substring(birth_date,1,10),'-','') as integer) as int_birth_Date
	from mst_users2
),
mst_users_with_age as (
	select *,
	-- 특정 날짜(2022년 5월 20)의 나이
	floor((int_specific_date-int_birth_Date)/10000) as age
	from mst_users_with_int_birth_date
),
mst_users_with_category as (
	select user_id,sex,age,concat(case when 20 <= age then sex else '' end,
								  case when age between 4 and 12 then 'C'
								       when age between 13 and 19 then 'T'
								       when age between 20 and 34 then '1'
								       when age between 35 and 49 then '2'
								       when age >=50 then '3' end) as category
	from mst_users_with_age
)
select p.category as product_category, u.category as user_category, count(*) as purchase_count
from action_log as p join mst_users_with_category as u on p.user_id = u.user_id
--구매 로그만 
where action = 'purchase'
group by 1,2
order by 1,2 

-- 2. 한 주에 며칠 사용되었는지를 집계하는 쿼리 
with action_log_with_dt as ( 
	select *, substring(stamp,1,10) as dt
	from action_log
),
action_day_count_per_day as ( 
	select user_id, count(distinct dt) as action_day_count
	from action_log_with_dt
	where dt between '2016-11-01' and '2016-11-07'
	group by user_id 
)
select action_day_count, count(distinct user_id) as user_count
from action_day_count_per_day 
group by action_day_count 
order by action_day_count

-- 3. 구성비와 구성비누계를 계산하는 쿼리 
with action_log_with_dt as ( 
	select *, substring(stamp,1,10) as dt
	from action_log
),
action_day_count_per_day as ( 
	select user_id, count(distinct dt) as action_day_count
	from action_log_with_dt
	where dt between '2016-11-01' and '2016-11-07'
	group by user_id 
)
select action_day_count, count(distinct user_id) as user_count,
	--구성비
	100.0 * count(distinct user_id)/sum(count(distinct user_id)) over() as composition_ratio,
	-- 구성비 누계
	100.0 * sum(count(distinct user_id)) over(order by action_day_count rows between unbounded preceding and current row)/ sum(count(distinct user_id)) over() as cumulative_ratio
from action_day_count_per_day 
group by action_day_count 
order by action_day_count

-- 4. 사용자들의 액션플래그를 집계하는 쿼리 
with user_action_flag as ( 
	--사용자가 액션하면 1 안하면 0 플래그 붙이
	select user_id,
			sign(sum(case when action = 'purchase' then 1 else 0 end)) as has_purchase,
			sign(sum(case when action = 'review' then 1 else 0 end)) as has_review,
			sign(sum(case when action = 'favorite' then 1 else 0 end)) as has_favorite
	from action_log
	group by 1
)
select * from user_action_flag

-- 5.모든 액션 조합에 대한 사용자 수 계산하기 
with user_action_flag as ( 
	--사용자가 액션하면 1 안하면 0 플래그 붙이
	select user_id,
			sign(sum(case when action = 'purchase' then 1 else 0 end)) as has_purchase,
			sign(sum(case when action = 'review' then 1 else 0 end)) as has_review,
			sign(sum(case when action = 'favorite' then 1 else 0 end)) as has_favorite
	from action_log
	group by 1
),
action_venn_diagram as ( 
	-- cube를 사용해서 모든 액션 조합 구하기 
	select has_purchase, has_review, has_favorite, count(1) as users
	from user_action_flag
	group by cube(has_purchase, has_review, has_favorite)
)
select * from action_venn_diagram
order by has_purchase, has_review, has_favorite

-- 6. cube구문을 사용하지 않고 ㅛ준 sql 구문만으로 작성하는 쿼리 
with user_action_flag as ( 
	--사용자가 액션하면 1 안하면 0 플래그 붙이
	select user_id,
			sign(sum(case when action = 'purchase' then 1 else 0 end)) as has_purchase,
			sign(sum(case when action = 'review' then 1 else 0 end)) as has_review,
			sign(sum(case when action = 'favorite' then 1 else 0 end)) as has_favorite
	from action_log
	group by 1
),
action_venn_diagram as ( 
	-- 모든 액션 조합을 개별적으로 구하고 union all로 결합
	-- 3개의 액션을 모두 한 경우 집계 
	select has_purchase, has_review, has_favorite, count(1) as users
	from user_action_flag
	group by has_purchase, has_review, has_favorite
	--3개의 액션 중에서 2개의 액션을 한 경우 집계
	union all 
	select null as has_purchase, has_review, has_favorite, count(1) as users
	from user_action_flag
	group by has_review, has_favorite
	union all 
	select has_purchase,null as has_review, has_favorite, count(1) as users
	from user_action_flag
	group by has_purchase, has_favorite
	union all
	select has_purchase, has_review, null as has_favorite, count(1) as users
	from user_action_flag
	group by has_purchase, has_review
	-- 3개의 액션 중 1개의 액션을 한 경우 집계
	union all 
	select null as has_purchase, null ashas_review, has_favorite, count(1) as users
	from user_action_flag
	group by has_favorite
	union all 
	select null as has_purchase, has_review, null as has_favorite, count(1) as users
	from user_action_flag
	group by has_review
	union all 
	select has_purchase,null as has_review, null as has_favorite, count(1) as users
	from user_action_flag
	group by has_purchase
	-- 액션과 관계 없이 모든 사용자 집계
	union all
	select null as has_purchase, null as has_review, null as has_favorite, count(1) as users
	from user_action_flag
)
select * from action_venn_diagram 
order by has_purchase, has_review, has_favorite

-- 7. 벤다이어 그램을 만들기 위해 데이터를 가공하는 쿼리  
with user_action_flag as ( 
	--사용자가 액션하면 1 안하면 0 플래그 붙이
	select user_id,
			sign(sum(case when action = 'purchase' then 1 else 0 end)) as has_purchase,
			sign(sum(case when action = 'review' then 1 else 0 end)) as has_review,
			sign(sum(case when action = 'favorite' then 1 else 0 end)) as has_favorite
	from action_log
	group by 1
),
action_venn_diagram as ( 
	-- cube를 사용해서 모든 액션 조합 구하기 
	select has_purchase, has_review, has_favorite, count(1) as users
	from user_action_flag
	group by cube(has_purchase, has_review, has_favorite)
)
select 
	-- 0,1 플래그를 문자열로 가공하기 
	case has_purchase when 1 then 'purcahse' when 0 then 'not purchase' else 'any'
	end as has_purchase,
	case has_review when 1 then 'review' when 0 then 'not review' else 'any'
	end as has_review,
	case has_favorite when 1 then 'favorite' when 0 then 'not favorite' else 'any'
	end as has_favorite,
	-- 모든 액션이 null인 사용자 수가 전체 사용자 수를 나타내므로 해당 레코드의 사용자 수를 window함수로 구하
	users, 100.0 * users/nullif(sum(case when has_purchase is null and has_review is null and has_favorite is null then users else 0 end)over(),0) as ratio 
from action_venn_diagram
order by 1,2,3
	