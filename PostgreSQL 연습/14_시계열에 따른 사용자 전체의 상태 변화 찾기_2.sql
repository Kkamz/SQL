--1. 지속률을 세로 기반으로 집계하는 쿼리 
with repeat_interval(index_name, interval_date) as (
	-- values 구문으로 테이블 생성 가능
	values ('01 day repeat',1),
			('02 day repeat',2),
			('03 day repeat',3),
			('04 day repeat',4),
			('05 day repeat',5),
			('06 day repeat',6),
			('07 day repeat',7)
),
action_log_with_index as (
	select u.user_id, u.register_date,
	-- 액션의 날짜와 로그 전체의 최신날짜를 날짜 형식으로 변환하기 
		cast(a.stamp as date) as action_date,
		max(cast(a.stamp as date)) over() as latest_date,
		-- 등록일로 부터 n 일 후의 날짜 계산
		r.index_name,
		cast(cast(u.register_date as date) + interval '1day' * r.interval_date as date) as index_date
	from mst_users3 as u
	left outer join action_log2 as a on u.user_id = a.user_id 
	cross join repeat_interval as r
),
user_action_flag as(
	select user_id, register_date,index_name,
	--(4) 등록일로 일로부터 n일 후에 액션을 했는지 플래그로 나타내기 
	sign(
		--(3) 사용자별로 등록일 n일 후에 한 액션의 합계 구하기 
		sum(
			--(1) 등록일 n일 후가 로그의 최신 날짜 이전인지 확인하기
			case when index_date <= latest_date then
			--(2) 등록일 n일 의 날짜에 액션을 했다면 1, 안했다면 0 지정  
				case when index_date = action_date then 1 else 0 end
			end
			)
	) as index_date_action
	from action_log_with_index
	group by 1,2,3,index_date
)
select register_date ,index_name, avg(100.0*index_date_action) as repeat_rate
from user_action_flag
group by 1,2
order by 1,2

--2. 정착률 지표를 관리하는 마스터 테이블을 작성
with repeat_interval(index_name,interval_begin_date,interval_end_date) as (
	values ('07 day retention',1,7),
			('14 day retention',8,14),
			('21 day retention',15,21),
			('28 day retention',22,28)
)
select * from repeat_interval
order by 1

-- 3. 정착률을 계산하는 쿼리 
with repeat_interval(index_name,interval_begin_date,interval_end_date) as (
	values ('07 day retention',1,7),
			('14 day retention',8,14),
			('21 day retention',15,21),
			('28 day retention',22,28)
),
action_log_with_index_date as (
	select u.user_id,u.register_date,
		-- 액션의 날짜와 로그 전체의 최신 날짜를 날짜 자료형으로 변환하기	
		cast(a.stamp as date) as action_date,
		max(cast(a.stamp as date)) over() as latest_date,r.index_name,
		-- 지표의 대상 기간 시작일과 종료일 계산하기
		cast(u.register_date::date + '1 day'::interval * r.interval_begin_date as date) as index_begin_date,
		cast(u.register_date::date + '1 day'::interval * r.interval_end_date as date) as index_end_date
	from mst_users3 as u
	left outer join action_log2 as a on u.user_id = a.user_id 
	cross join repeat_interval as r
),
user_action_flag as(
	select user_id, register_date,index_name,
	--(4) 지표의 대상기간에 액션을 했는지 플래그로 나타내기 
	sign(
		--(3) 사용자 별로 대상 기간에 한 액션의 합계 구하
		sum(
			--(1) 대상 기간의 종료일이 로그의 최신 날짜 이전인지 확인 
			case when index_end_date <= latest_date then
			--(2) 지표의 대상 기간에 액션을 했다면 1 안했다면 0  
				case when action_date between index_begin_date and index_end_date then 1 else 0 end
			end
			)
	) as index_date_action
	from action_log_with_index_date
	group by 1,2,3,index_begin_date,index_end_date
)
select register_date ,index_name, avg(100.0*index_date_action) as index_rate
from user_action_flag 
group by 1,2
order by 1,2

--4. 지속률 지표를 관리하는 마스터 테이블을 정착률 형식으로 수정한 쿼리 
with repeat_interval(index_name,interval_begin_date,interval_end_date) as (
	values  ('01 day repeat',1,1),
			('02 day repeat',2,2),
			('03 day repeat',3,3),
			('04 day repeat',4,4),
			('05 day repeat',5,5),
			('06 day repeat',6,6),
			('07 day repeat',7,7),
			('07 day retention',1,7),
			('14 day retention',8,14),
			('21 day retention',15,21),
			('28 day retention',22,28)
)
select * from repeat_interval
order by index_name

-- 5. n일 지속률들을 집계하는 쿼리 
with repeat_interval(index_name,interval_begin_date,interval_end_date) as (
	values  ('01 day repeat',1,1),
			('02 day repeat',2,2),
			('03 day repeat',3,3),
			('04 day repeat',4,4),
			('05 day repeat',5,5),
			('06 day repeat',6,6),
			('07 day repeat',7,7),
			('07 day retention',1,7),
			('14 day retention',8,14),
			('21 day retention',15,21),
			('28 day retention',22,28)
),
action_log_with_index_date as (
	select u.user_id,u.register_date,
		-- 액션의 날짜와 로그 전체의 최신 날짜를 날짜 자료형으로 변환하기	
		cast(a.stamp as date) as action_date,
		max(cast(a.stamp as date)) over() as latest_date,r.index_name,
		-- 지표의 대상 기간 시작일과 종료일 계산하기
		cast(u.register_date::date + '1 day'::interval * r.interval_begin_date as date) as index_begin_date,
		cast(u.register_date::date + '1 day'::interval * r.interval_end_date as date) as index_end_date
	from mst_users3 as u
	left outer join action_log2 as a on u.user_id = a.user_id 
	cross join repeat_interval as r
),
user_action_flag as(
	select user_id, register_date,index_name,
	--(4) 지표의 대상기간에 액션을 했는지 플래그로 나타내기 
	sign(
		--(3) 사용자 별로 대상 기간에 한 액션의 합계 구하
		sum(
			--(1) 대상 기간의 종료일이 로그의 최신 날짜 이전인지 확인 
			case when index_end_date <= latest_date then
			--(2) 지표의 대상 기간에 액션을 했다면 1 안했다면 0  
				case when action_date between index_begin_date and index_end_date then 1 else 0 end
			end
			)
	) as index_date_action
	from action_log_with_index_date
	group by 1,2,3,index_begin_date,index_end_date
)
select index_name,avg(100.0*index_date_action) as repeat_rate
from user_action_flag
group by 1
order by 1