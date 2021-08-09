-- (�⺻)
-- 1. ���� A�� ������ �� Ƚ���� ���Ͻÿ�.
select 
  count(*) as cnt 
from 
  practice
where 
  user_id = 'A'

-- 2. ���� A�� ������ ��¥�鸸 �ߺ� ���� ���Ͻÿ�.
select 
  distinct action_date as date
from
  practice as p 
where 
   user_id = 'A'
  
  
-- 3. ���� C�� �� ���ž��� ���Ͻÿ�.
select 
  sum(revenue) as total
from 
  practice
where user_id = 'C'
   
   
-- 4. 3/3�� ���Ÿ� �� �������� �ߺ� ���� ���Ͻÿ�.
select
  distinct user_id as user
from
  practice
where
  action_date = '2021-03-03'

-- 5. product_id 4�� ��ǰ�� �ȸ� �� ������ ���� �� ���� ����Ͻÿ�.
select
  sum(amount) as total,count(product_id) as buy_count
from
  practice
where
  product_id = 4

-- (����) ���ǹ� Ȱ���ϱ�
-- 3/3�� 3/5 ���̿� product_id 5�� ��ǰ�� ������ ����(��)�� ���Ͻÿ�.
select 
  user_id as user
from 
  practice
where
  action_date >= '2021-03-03' and action_date <= '2021-03-05' and product_id = 5
  
-- ���� B�� product_id 2�� ��ǰ�� 2�� �̻� ������ ��¥���� �ߺ� ���� ����Ͻÿ�.
select
  action_date as date
from 
  practice
where
  user_id = 'B' and product_id ='2' and amount >=2
  
-- �ѱ�(KR)���� product_id 2�� ��ǰ�� �ȸ� ������ ���Ͻÿ�.
select
  count(*) as pd_2_cnt
from
  practice
where
  country ='KR' and product_id = 2
  
-- 3/7�� ���� D�� ��ǰ�� 4�� �̻� ������ �ǵ鿡 ���Ͽ� �� ���ž��� ���Ͻÿ�.
select
  sum(revenue) as total_sum
from
  practice
where
  user_id = 'D' and action_date ='2021-03-07' and amount >= 4
  
-- 3/2�� 3/5�� A�� D�� ������ ��ǰ���� �ߺ� ���� ����Ͻÿ�.
select 
  product_id
from
  practice
where
  (user_id = 'A' and (action_date = '2021-03-02' or action_date = '2021-03-05')) or 
  (user_id = 'D' and (action_date = '2021-03-02' or action_date = '2021-03-05'))