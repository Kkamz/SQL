-- 1. 집약 함수를 사용해서 테이블 전체의 특징량을 계산하는 쿼리
select count(*) as total_cnt,
		count(distinct user_id) as user_cnt,
		count(distinct product_id) as product_cnt,
		sum(score) as sum,
		avg(score) as avg,
		max(score) as max,
		min(score) as min
from review

-- 2. 사용자 기반으로 데이터를 분할하고 집약함수를 적용하는 쿼리
select user_id,
		count(*) as total_cnt,
		count(distinct product_id) as product_cnt,
		sum(score) as sum,
		avg(score) as avg,
		max(score) as max,
		min(score) as min
from review
group by user_id

-- 3. 윈도 함수를 사용해 집약 함수의 결과와 원래 값을 동시에 다루는 쿼리 
select user_id, product_id,score,
		-- 전체 평균 
		avg(score) over() as avg_score,
		-- 사용자 별 평균 
		avg(score) over(partition by user_id) as user_avg_score,
		-- 전체 - 사용자별 평균 
		score - avg(score) over(partition by user_id) as user_avg_score_diff
from review

-- 4. 윈도 함수의 order by 구문을 사용해 테이블 내부의 순서를 다루는 쿼리 
select product_id,score,
		row_number() over(order by score desc) as row,
		Rank() over(order by score desc) as rank,
		dense_rank() over(order by score desc) as dense_rank,
		-- 현재 행보다 앞에있는 행의 값 추출 
		LAG(product_id) over(order by score desc) as lag1, 
		LAG(product_id,2) over(order by score desc) as lag2,
		-- 현재 행보다 뒤에 있는 행의 값 추출
		lead(product_id) over(order by score desc) as lead1,
		lead(product_id,2) over(order by score desc) as lead2
from popular_products 
order by row

-- 5. order by 구문과 집약 함수를 조합해서 계산하는 쿼리 
select product_id, score,
		row_number() over(order by score desc) as row,
		-- 순위 상위부터의 누계점수 계산 
		sum(score) over(order by score desc rows between unbounded preceding and current row) as cum_score,
		-- 현재 행과 앞뒤의 행이 가진 값을 기반으로 평균 점수 구하기 
		avg(score) over(order by score desc rows between 1 preceding and 1 following) as local_avg,
		-- 순위가 높은 상풍 ID 추출 
		first_value(product_id) over(order by score desc rows between unbounded preceding and unbounded following) as first_value,
		-- 순위가 낮은 상품 ID 추출 
		last_value(product_id) over(order by score desc rows between unbounded preceding and unbounded following) as last_value
from popular_products 
order by row

-- 6. 윈도 프레임 지정별 상품 ID를 집약하는 쿼리 
-- array_agg 사용 
select product_id,
		row_number() over(order by score desc) as row,
		-- 가장 앞 순위부터 가장 뒷 순위까지의 범위를 대상으로 상품 ID 집약하기 
		array_agg(product_id) over(order by score desc rows between unbounded preceding and unbounded following) as whole_agg,
		-- 가장 앞 순위부터 현재 순위까지의 범위를 대상으로 상품 ID 집약하기 
		array_agg(product_id) over(order by score desc rows between unbounded preceding and current row) as cum_agg,
		-- 순위 하나 앞과 하나 뒤까지의 범위를 대상으로 상품 ID 집약하기 
		array_agg(product_id) over(order by score desc rows between 1 preceding and 1 following) as local_agg
from popular_products 
where category ='action'
order by row

-- 7. 윈도 함수를 사용해 카테고리들의 순위를 계산하는 쿼리
select category, product_id, score,
		row_number() over(partition by category order by score desc) as row,
		rank() over(partition by category order by score desc) as rank,
		dense_rank() over(partition by category order by score desc) as dense_rank
from popular_products 
order by category,row

-- 8. 카테고리들의 순위 상위 2개까지의 상품을 추출하는 쿼리 
select * from 
(select category, product_id,score,rank() over(partition by category order by score desc) as rank
from popular_products) as popular_products_with_rank
where rank <= 2
order by category,rank

-- 9. 카테고리별 순위 최상위 상품을 추출하는 쿼리 
select distinct category,
		first_value(product_id) over(partition by category order by score desc rows between unbounded preceding and unbounded following) as product_id
from popular_products 

