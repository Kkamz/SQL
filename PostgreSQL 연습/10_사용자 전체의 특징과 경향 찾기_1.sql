-- 1. 액션 수와 비율을 계산하는 쿼리 
-- UU는 Unique user
with stats as(
	-- 로그 전체의 유니크 사용자 수 구하
	select count(distinct session) as total_uu
	from action_log
)
select l.action, 
		-- 액션 UU
		count(distinct l.session),
		-- 액션의 수
		count(1) as action_count,
		-- 전체 UU
		s.total_uu,
		-- 사용률 : <액션 수> / <액션 UU>
		100.0 * count(distinct l.session) / s.total_uu as usage_rate,
		-- 1인당 액션수 : < 액션 수> / <액션UU> 
		1.0*count(1) / count(distinct l.session) as count_per_user
from action_log as l
-- 로그 전체의 유니크 사용자 수를 모든 레코드에 결합하기
cross join stats as s 
group by l.action,s.total_uu

-- 2. 로그인 상태를 판별하는 쿼리 
with action_log_with_status as ( 
	select session ,user_id ,action,
			-- user_id가 NULL또는 빈문자가 아닌 경우는 login이라고 판정하기
			case when coalesce(user_id,'') <> '' then 'login' else 'guest' end as login_status
	from action_log al 
)
select *
from action_log_with_status

-- 3. 로그인 상태에 따라 액션 수 등을 따로 집계하는 쿼리 
with action_log_with_status as ( 
	select session ,user_id ,action,
			-- user_id가 NULL또는 빈문자가 아닌 경우는 login이라고 판정하기
			case when coalesce(user_id,'') <> '' then 'login' else 'guest' end as login_status
	from action_log al 
)
select coalesce(action,'all') as action, 
		coalesce(login_status,'all') as login_status,
		count(distinct session) as action_uu,
		count(1) as action_count
from action_log_with_status
group by rollup(action, login_status)

-- 4. 회원 상태를 판별하는 쿼리 
with action_log_with_status as ( 
	select session,user_id,action,
	-- 로그를 타임스탬프 순서로 나열하고, 한번이라도 로그인한 사용자일 경우,
	-- 이후의모든 로그 상태를 member로 설정 
	case when coalesce(max(user_id) over(partition by session order by stamp rows between unbounded preceding and current row),'') <> ''
		then 'member'
		else 'none'
		end as member_status,
	stamp 
	from action_log al 
)
select * from action_log_with_status

-- 5. 시용자의 생일을 계산하는 쿼리 
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
)
select user_id,sex,birth_date,age
from mst_users_with_age

-- 6. 성별과 연령으로 연령별 구분을 계산하는 쿼리 
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
select * from mst_users_with_category

-- 7. 연령별 구분의 사람 수를 계산하는 쿼리 
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
select category, count(1) as user_count 
from mst_users_with_category
group by category
