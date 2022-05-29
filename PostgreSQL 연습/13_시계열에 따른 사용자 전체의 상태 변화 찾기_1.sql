--1. 날짜별 등록 수의 추이를 집계하는 쿼리
select register_date, count(distinct user_id) as regis_count
from mst_users2 mu 
group by 1
order by 1

--2. 매달 등록수와 전월비를 계산하는 쿼리 
with mst_users_with_year_month as (
	select *,substring(register_date,1,7) as year_month 
	from mst_users2 mu 
)
select year_month, count(distinct user_id) as register_count,
		lag(count (distinct user_id)) over(order by year_month) as month_over_month_ratio
from mst_users_with_year_month
group by 1

-- 3. 디바이스들의 등록수를 집계하는 쿼리 
with mst_users_with_year_month as (
	select *,substring(register_date,1,7) as year_month 
	from mst_users2 mu 
)
select year_month,count(distinct user_id) as register_count,
		count(distinct case when register_device = 'pc' then user_id end) as register_pc,
		count(distinct case when register_device = 'sp' then user_id end) as register_sp,
		count(distinct case when register_device = 'app' then user_id end) as register_app
from mst_users_with_year_month
group by 1

-- 4. '로그 최근 일자'와 '사용자별 등록일의 다음날'을 계산하는 쿼리
with action_log_with_mst_users as (
	select u.user_id,u.register_date ,cast(a.stamp as date) as action_date,
			max(cast(a.stamp as date)) over() as latest_date,
			cast(u.register_date::date + '1 day'::interval as date) as next_1day
	from mst_users2 u
		left outer join action_log2 as a on u.user_id = a.user_id 
)
select * from action_log_with_mst_users
order by register_date 

-- 5. 사용자의 액션 플래그를 계산하는 쿼리 
with action_log_with_mst_users as (
	select u.user_id,u.register_date ,cast(a.stamp as date) as action_date,
			max(cast(a.stamp as date)) over() as latest_date,
			cast(u.register_date::date + '1 day'::interval as date) as next_1day
	from mst_users2 u
		left outer join action_log2 as a on u.user_id = a.user_id 
),
user_action_flag as(
	select user_id, register_date,
	--(4) 등록일 다음날에 액션을 했는지 안했는지 플래그로 나타내기
	sign(
		--(3) 사용자별로 등록일 다음날에 한 액션의 합계 구하기
		sum(
			--(1) 등록일 다음날이 로그의 최신 날짜 이전인지 확인하기
			case when next_1day <= latest_date then
			--(2) 등록일 다음날의 날짜에 액션을 했다면 1, 안했다면 0 지정  
				case when next_1day = action_date then 1 else 0 end
			end
			)
	) as next_1_day_action
	from action_log_with_mst_users
	group by 1,2
)
select * from user_action_flag
order by register_date,user_id

-- 6. 다음날 지속률을 계산하는 쿼리 
with action_log_with_mst_users as (
	select u.user_id,u.register_date ,cast(a.stamp as date) as action_date,
			max(cast(a.stamp as date)) over() as latest_date,
			cast(u.register_date::date + '1 day'::interval as date) as next_1day
	from mst_users2 u
		left outer join action_log2 as a on u.user_id = a.user_id 
),
user_action_flag as(
	select user_id, register_date,
	--(4) 등록일 다음날에 액션을 했는지 안했는지 플래그로 나타내기
	sign(
		--(3) 사용자별로 등록일 다음날에 한 액션의 합계 구하기
		sum(
			--(1) 등록일 다음날이 로그의 최신 날짜 이전인지 확인하기
			case when next_1day <= latest_date then
			--(2) 등록일 다음날의 날짜에 액션을 했다면 1, 안했다면 0 지정  
				case when next_1day = action_date then 1 else 0 end
			end
			)
	) as next_1_day_action
	from action_log_with_mst_users
	group by 1,2
)
select register_date, avg(100.0*next_1_day_action) as repeat_rate_1_day
from user_action_flag
group by 1
order by 1

-- 7. 지속률 지표를 관리하는 마스터 테이블을 작성하는 쿼리 
with repeat_interval(index_name, interval_date) as (
	-- values 구문으로 테이블 생성 가능
	values ('01 day repeat',1),
			('02 day repeat',2),
			('03 day repeat',3),
			('04 day repeat',4),
			('05 day repeat',5),
			('06 day repeat',6),
			('07 day repeat',7)
)
select * from repeat_interval
order by 1