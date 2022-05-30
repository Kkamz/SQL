-- 1. 미래 or 과거의 날짜/시간을 계산하는 쿼리
-- interval 자료형의 데이터에 사칙연산 활용
select user_id,
	   register_stamp::timestamp as register_stamp,
	   register_stamp::timestamp + '1 hour'::interval as after_1hour,
	   register_stamp::timestamp -'30 minutes'::interval as before_30min,
	   register_stamp::date as register_date,
	   (register_stamp::date + '1 day'::interval)::date as after_1day,
	   (register_stamp::date - '1 month'::interval)::date as before_1month
from mst_users_with_dates muwd 

-- 2. 두 날짜의 차이를 계산하는 쿼리
select user_id, current_date as today,
	register_stamp::date as register_date,
	current_date - register_stamp::date as diff_days
from mst_users_with_dates muwd 


-- 3. age 함수를 사용해 나이를 계산하는 쿼리 
-- age함수 활용 & extract로 연도 추출해서 나이 계
select user_id, current_date as today,
	register_stamp::date as register_date,
	birth_date::date as birth_date,
	extract(year from age(birth_date::date)) as current_age,
	extract(year from age(register_stamp::date, birth_date::date)) as register_age
from mst_users_with_dates muwd

-- 4. 날짜를 정수로 표현하여 나이를 계산하는 함수
-- 2000년생 나이 구하기 
select floor((20220429-20000229)/10000) as age

-- 5. 등록 시점과 현재 시점의 나이를 문자열로 계산하는 쿼리
select user_id, substring(register_stamp,1,10) as register_date,
		birth_date,floor((cast(replace(substring(register_stamp,1,10),'-','') as integer)-cast(replace(birth_date,'-','')as integer))/10000) as register_age,
		floor((cast(replace(cast(current_date as text),'-','')as integer)-cast(replace(birth_date,'-','') as integer))/10000) as current_age
from mst_users_with_dates muwd 

-- 6. Inet자료형을 사용한 IP주소 비교 쿼리 
select cast('127.0.0.1' as inet) < cast('127.0.0.2' as inet) as lt,
		cast('127.0.0.1' as inet) > cast('192.168.0.1' as inet) as gt
		
-- 7. inet 자료형을 사용해 IP 주소 범위를 다루는 쿼리
-- address/y 형식의 네트워크 범위에 IP주소가 포함되어 있는지 판정 가능 ( << or >> 사용)  
select cast('127.0.0.1' as inet) << cast('127.0.0.0/8' as inet) as is_contained

-- 8. IP 주소에서 4개의 10진수 부분을 추출하는 쿼리 
select ip, cast(split_part(ip,'.',1) as integer) as ip_part1,
			cast(split_part(ip,'.',2) as integer) as ip_part2,
			cast(split_part(ip,'.',3) as integer) as ip_part3,
			cast(split_part(ip,'.',4) as integer) as ip_part4
from (select cast('192.168.0.1' as text) as ip) as t

-- 9. IP조소를 정수 자료형 표기로 변환하는 쿼리
select ip,
		cast(split_part(ip,'.',1) as integer) * 2^24 +
		cast(split_part(ip,'.',2) as integer) * 2^16 +
		cast(split_part(ip,'.',3) as integer) * 2^8 +
		cast(split_part(ip,'.',4) as integer) * 2^0 as ip_integer
from (select cast('192.168.0.1' as text) as ip) as t

-- 10. IP주소를 0으로 메운 문자열로 변환하는 쿼리 
select t.ip, 
		lpad(split_part(t.ip,'.',1),3,'0')
		||lpad(split_part(t.ip,'.',2),3,'0')
		||lpad(split_part(t.ip,'.',3),3,'0')
		||lpad(split_part(t.ip,'.',4),3,'0') as ip_padding
from (select cast('192.168.0.1' as text) as ip) as t
