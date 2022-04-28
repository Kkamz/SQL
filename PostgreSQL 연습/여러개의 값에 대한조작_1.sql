-- 1.문자열을 연결하는 쿼리
select user_id, concat(pref_name,city_name) as pref_city
from mst_user_location 

-- 2. q1,q2 컬럼 비교하는 쿼리
-- sign -> 양수면 1, 음수면 -1, 0이면 0 
select year,q1,q2, case when q1 <q2 then '+'
						when q1 = q2 then '-'
						else '-'
						end as judge_q1_q2,
	   q2-q1 as diff_q2_q1,sign(q2-q1) as sign_q2_q1
from quarterly_sales qs 
order by year

-- 3. 연간 최대/최소 4분기 매출을 찾는 쿼리
select year, greatest(q1,q2,q3,q4) as G_sales,least(q1,q2,q3,q4) as L_sales
from quarterly_sales qs 
order by year

-- 4. 단순한 연산으로 평균 4분기 매출을 구하는 쿼리 
select year, (q1+q2+q3+q4)/4 as AVG_Sales
from quarterly_sales qs 
order by year

-- 5. coalesce를 활용하여 NULL을 0으로 변환 후 평균값 구하는 쿼리 
select year, (coalesce(q1,0)+coalesce(q2,0)+coalesce(q3,0)+coalesce(q4,0)) /4 as AVG_sales
from quarterly_sales qs 
order by year

-- 6. NULL이 아닌 컬럼만을 사용하여 평균값 구하는 쿼리 
select year, 
(coalesce(q1,0)+coalesce(q2,0)+coalesce(q3,0)+coalesce(q4,0)) / (sign(coalesce(q1,0))+sign(coalesce(q2,0))+sign(coalesce(q3,0))+sign(coalesce(q4,0))) as AVG_sales
from quarterly_sales qs 
order by 1

-- 7. 정수 자료형의 데이터를 나누는 쿼리 
select dt, ad_id, cast(clicks as double precision) / impressions as ctr,100.0*clicks/impressions as ctr_as_percent
from advertising_stats as2 
where dt = '2017-04-01'
order by 1,2

-- 8. 0으로 나누는 것을 피해 CTR을 계산하는 쿼리 
-- case로 분모가 0일 경우를 분기해서, 0으로 나누지 않게
-- NULLIF로 분모가 0이라면 NULL로 변환해서, 0으로 나누지 않
select dt, ad_id, case when impressions >0 then 100.0*clicks/impressions
						end as ctr_as_percent_by_case
		,100.0*clicks/NULLIF(impressions,0) as ctr_as_percent_by_null
from advertising_stats as2 
order by 1,2

-- 9. 1차원 데이터의 절댓값과 제곱 편균 제곱근을 계산하는 쿼리 
select abs(x1-x2) as abs ,sqrt(power(x1-x2,2)) as rms
from location_1d ld 

-- 10. 이차원 테이블에 대해 제곱평균제곱근(유클리드 거리)를 구하는 쿼리 
-- postgresql에서는 <->를 활용하여 거리 구하기 가
select sqrt(power(x1-x2,2)+power(y1-y2,2)) as dist,
	   point(x1,y1) <-> point(x2,y2) as dist2
from location_2d ld 