select * from practice p 

--1. 국가가 한국(KR)인 유저들이 3/5 이후로 구매한 총 상품 수량을 구하시오
select
  sum(amount) as total
from
  practice
where
  country = 'KR' and action_date >= '2021-03-05'
  
--2. 유저 B가 총 구매액 150 이상을 구매했던 날짜와 각 해당 날짜에 구매한 총 수량을 출력하시오.
select 
  action_date, sum(amount) as total
from
  practice
where
  user_id = 'B' and revenue >= 150
group by
  action_date
  
--3. 날짜별로 각 유저들이 product_id 1번 상품을 구매한 총 수량을 날짜 및 유저 순으로 정렬하여 출력하시오.
select 
  action_date, user_id, sum(amount) as total
from
  practice p
where 
  product_id = 1
group by 
  action_date, user_id
order by 
  action_date, user_id
  
--4. product_id 2번 상품이 팔렸던 날짜들의 날짜별 총 구매액을 구매액 역순(내림차순)으로 정렬하여 출력하시오.
select 
  action_date, sum(amount) as total
from
  practice
where
  product_id = 2
group by
  action_date 
order by 
  total desc
  
--5. 구매액이 가장 많은 유저 한 명만 출력하시오. (WHERE절을 사용하지 않고)
select
  user_id
from
  practice
group by
  user_id
order by
  sum(revenue)
limit 1
  
  
 
