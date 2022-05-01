-- 1. 행으로 저장된 지표 값을 열로 변환하는 쿼리 
select dt,
	max(case when indicator = 'impressions' then val end) as impressions,
	max(case when indicator = 'sessions' then val end) as sessions,
	max(case when indicator = 'users' then val end) as users
from daily_kpi dk 
group by 1
order by 1

-- 2. 행을 집약해서 쉼표로 구분된 문자열로 변환하기
select purchase_id,
		string_agg(product_id,',') as group_concat,
		sum(price) as amount
from purchase_detail_log pdl 
group by 1
order by 1

-- 3. 일련 번호를 가진 피벗 테이블을 사용해 행으로 변환하는 쿼리
select q.year,
		case when p.idx = 1 then 'q1'
			 when p.idx = 2 then 'q2'
			 when p.idx = 3 then 'q3'
			 when p.idx = 4 then 'q4'
			 end as quarter,
		case when p.idx = 1 then q.q1
			 when p.idx = 2 then q.q2
			 when p.idx = 3 then q.q3 
			 when p.idx = 4 then q.q4
			 end as sales
from quarterly_sales as q
cross join (select 1 as idx
			union all select 2 as idx
			union all select 3 as idx
			union all select 4 as idx) as p
			
-- 4. 테이블 함수를 사용해 배열을 행으로 전개하는 쿼리
select unnest(array['A001','A002','A003']) as product_id

-- 5. 테이블 함수를 사용해 쉼표로 구분된 문자열 데이터를 행으로 전개하는 쿼리 
select purchase_id, product_id 
from purchase_log p cross join unnest(string_to_array(product_ids,',')) as product_id

-- 6. PostgreSQL에서 쉼표로 구분된 데이터를 행으로 전개하는 쿼리
select purchase_id, regexp_split_to_table(product_ids,',') as product_id
from purchase_log

-- 7. 일련 번호를 가진 피벗 테이블을 만드는 쿼리 
select *
from (select 1 as idx
	  union all select 2 idx 
	  union all select 3 idx) as pivot
	  
-- 8. split_part 함수의 사용 예시
select split_part('A001,A002,A003',',',1) as part1,
		split_part('A001,A002,A003',',',2) as part2,
		split_part('A001,A002,A003',',',3) as part3

-- 9. 문자 수의 차이를 사용해 상품 수를 계산하는 쿼리 
-- 상품 ID 문자열을 기반으로 쉼표를 제거하고, 문자 수의 차이를 계산해서 상품 수 구하기 
select purchase_id, product_ids,
		1 + char_length(product_ids) - char_length(replace(product_ids,',','')) as product_num
from purchase_log pl 

-- 10. 피벗 테이블을 사용해 문자열을 행으로 전개하는 쿼리 
select l.purchase_id, l.product_ids, p.idx, split_part(l.product_ids,',',p.idx) as product_id
from purchase_log as l join
	(select 1 as idx
	union all select 2 as idx
	union all select 3 as idx) as p on p.idx <=(1 + char_length(l.product_ids) - char_length(replace(l.product_ids,',','')) )