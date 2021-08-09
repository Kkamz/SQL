-- (기본)
-- 1. 유저 A가 구매한 총 횟수를 구하시오.
select 
  count(*) as cnt 
from 
  practice
where 
  user_id = 'A'

-- 2. 유저 A가 구매한 날짜들만 중복 없이 구하시오.
select 
  distinct action_date as date
from
  practice as p 
where 
   user_id = 'A'
  
  
-- 3. 유저 C의 총 구매액을 구하시오.
select 
  sum(revenue) as total
from 
  practice
where user_id = 'C'
   
   
-- 4. 3/3에 구매를 한 유저들을 중복 없이 구하시오.
select
  distinct user_id as user
from
  practice
where
  action_date = '2021-03-03'

-- 5. product_id 4번 상품이 팔린 총 수량과 구매 건 수를 출력하시오.
select
  sum(amount) as total,count(product_id) as buy_count
from
  practice
where
  product_id = 4

-- (응용) 조건문 활용하기
-- 3/3과 3/5 사이에 product_id 5번 상품을 구매한 유저(들)을 구하시오.
select 
  user_id as user
from 
  practice
where
  action_date >= '2021-03-03' and action_date <= '2021-03-05' and product_id = 5
  
-- 유저 B가 product_id 2번 상품을 2개 이상 구매한 날짜들을 중복 없이 출력하시오.
select
  action_date as date
from 
  practice
where
  user_id = 'B' and product_id ='2' and amount >=2
  
-- 한국(KR)에서 product_id 2번 상품이 팔린 개수를 구하시오.
select
  count(*) as pd_2_cnt
from
  practice
where
  country ='KR' and product_id = 2
  
-- 3/7에 유저 D가 상품을 4개 이상 구매한 건들에 대하여 총 구매액을 구하시오.
select
  sum(revenue) as total_sum
from
  practice
where
  user_id = 'D' and action_date ='2021-03-07' and amount >= 4
  
-- 3/2과 3/5에 A와 D가 구매한 상품들을 중복 없이 출력하시오.
select 
  product_id
from
  practice
where
  (user_id = 'A' and (action_date = '2021-03-02' or action_date = '2021-03-05')) or 
  (user_id = 'D' and (action_date = '2021-03-02' or action_date = '2021-03-05'))