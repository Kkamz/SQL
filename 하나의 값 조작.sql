--1. 레이블 변경하는 쿼리
-- !!주의 postgresql에서 문자열은 작은따움표('')로 설정!! 

select user_id, case when register_device = 1 then '데스크탑'
				    when register_device = 2 then '스마트폰'
				    when register_device = 3 then '애플리케이션'
				    else  '' end as device_name
from mst_users mu ;

-- 2. 레퍼러 도메인을 추출하는 쿼리 
-- 정규 표현식 사용 
select stamp, substring(referrer from 'https?://([^/]*)') as referrer_host
from access_log al

-- 3. URL 경로와 GET 매개변수에 있는 특정 키 값을 추출하는 쿼리 
-- GET 매개변수의 id 추출하기 
select stamp, url,substring(url from '//[^/]+([^?#]+)') as path, substring(url from 'id=([^&]*)') as id
from access_log al 

-- 4. URL 경로를 슬래시로 분할해서 계층을 추출하는 쿼리 
-- 경로를 슬래시로 자르기 / 경로가 반드시 슬래시로 시작하므로 2번째 요소가 마지막 계층 
select stamp,url, split_part(substring(url from '//[^/]+([^?#]+)'),'/',2) as path1,
	   split_part(substring(url from '//[^/]+([^?#]+)'),'/',3) as path2
from access_log al 		

-- 5. 현재 날짜와 타임스탬프를 추출하는 쿼리 
-- current_date와 current_timestamp 상수 사용 
select current_date as dt, current_timestamp as stamp

-- 6. 문자열을 날짜 자료형, 타임스탬프 자료형으로 변환하는 쿼리
-- cast 사용 
select cast('2016-01-30' as date) as dt, cast('2016-01-30 12:00:00' as timestamp) as stamp

-- 7. 타임스탬프 자료형의 데이터에서 연,월,일 등을 추출하는 쿼리 
-- EXTRACT 사용 
select extract(year from t.stamp) as year,
	   extract(month from t.stamp) as month,
	   extract(day from t.stamp) as day,
	   extract(Hour from t.stamp) as hour
from (select cast('2016-01-30 12:00:00' as timestamp) as stamp) as t

-- 8. 타임스탬프를 나타내는 문자열에서 연,월,일 등을 추출하는 쿼리 
-- substing 사용 / cast 사용해서 날짜를 문자열로 
select t.stamp,substring(t.stamp,1,4) as year,
	   substring(t.stamp,6,2) as month,
	   substring(t.stamp,9,2) as day,
	   substring(t.stamp,12,2) as hour,
	   substring(t.stamp,1,7) as year_month
from (select cast('2016-01-30 12:00:00' as text) as stamp) as t

-- 9. 구매액에서 할인 쿠폰 값을 제외한 매출금액을 구하는 쿼리
select purchase_id, amount,coupon,
		(amount-coupon) as discount_amount1, (amount-coalesce(coupon,0)) as discount_amount2
from purchase_log_with_coupon plwc 