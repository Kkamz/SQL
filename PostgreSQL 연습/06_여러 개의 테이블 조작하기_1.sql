-- 1. UNION ALL 구문을 사용해 테이블을 세로로 결합하는 쿼리 
select 'app1' as app_name, user_id, name, email from app1_mst_users
union all 
select 'app2' as app_name, user_id, name, Null as email from app2_mst_users

-- 2. 여러개의 테이블을 결합해서 가로로 정렬하는 쿼리
select m.category_id, m.name,s.sales,r.product_id 
from mst_categories as m
join category_sales as s on m.category_id =s.category_id
join product_sale_ranking as r on m.category_id = r.category_id

-- 3. 마스터 테이블의 행 수를 변경하지 않고 여러 개의 테이블을 가로로 정렬하는 쿼리
select m.category_id, m.name,s.sales,r.product_id as top_sale_pro
from mst_categories as m 
left join category_sales as s on m.category_id = s.category_id 
left join product_sale_ranking as r on m.category_id = r.category_id and r.rank = 1

-- 4. 상관 서브쿼리로 여러 개의 테이블을 가로로 정렬하는 쿼리 
select m.category_id, m.name,
	(select s.sales from category_sales as s 
	where m.category_id  = s.category_id) as sales,
	(select r.product_id from product_sale_ranking as r 
	where m.category_id = r.category_id order by sales desc
	limit 1) as top_sale_product
from mst_categories as m

-- 5. 신용카드 등록과 구매 이력 유무를 0과 1이라는 플래그로 나타내는 쿼리 
select m.user_id, m.card_number, count(p.user_id) as purchase_cnt,
		case when m.card_number is not null then 1 else 0 end as has_card,
		-- 구매이력이 있는 경우 1,없는 경우 0
		sign(count(p.user_id)) as has_purchased
from mst_users_with_card_number as m
left join purchase_log_t as p on m.user_id =p.user_id 
group by m.user_id , m.card_number 
order by m.user_id

-- 6. 카테고리별 순위를 추가한 테이블에 이름 붙이기
-- with절 활용 
with product_sale_ranking as (
	select category_name, product_id,sales,
			row_number() over(partition by category_name order by sales desc) as rank 
	from product_sales
)
select * from product_sale_ranking

-- 7. 카테고리들의 순위에서 유니크한 순위목록을 계산하는 쿼리 
with product_sale_ranking as (
	select category_name, product_id,sales,
			row_number() over(partition by category_name order by sales desc) as rank 
	from product_sales
),
mst_rank as(
select distinct rank 
from product_sale_ranking
)
select * from mst_rank
order by rank

-- 8. 카테고리들의 순위를 횡단적으로 출력하는 쿼리 
with product_sale_ranking as (
	select category_name, product_id,sales,
			row_number() over(partition by category_name order by sales desc) as rank 
	from product_sales
),
mst_rank as(
	select distinct rank 
	from product_sale_ranking
	order by rank
)
select m.rank,
		r1.product_id as dvd,
		r1.sales as dvd_sales,
		r2.product_id as cd,
		r2.sales as cd_sales,
		r3.product_id as book,
		r3.sales as book_sales
from mst_rank as m
left join product_sale_ranking as r1 on m.rank = r1.rank
and r1.category_name = 'dvd'
left join product_sale_ranking as r2 on m.rank = r2.rank
and r2.category_name = 'cd'
left join product_sale_ranking as r3 on m.rank = r3.rank
and r3.category_name = 'book'
