select * from practice p 

--1. ������ �ѱ�(KR)�� �������� 3/5 ���ķ� ������ �� ��ǰ ������ ���Ͻÿ�
select
  sum(amount) as total
from
  practice
where
  country = 'KR' and action_date >= '2021-03-05'
  
--2. ���� B�� �� ���ž� 150 �̻��� �����ߴ� ��¥�� �� �ش� ��¥�� ������ �� ������ ����Ͻÿ�.
select 
  action_date, sum(amount) as total
from
  practice
where
  user_id = 'B' and revenue >= 150
group by
  action_date
  
--3. ��¥���� �� �������� product_id 1�� ��ǰ�� ������ �� ������ ��¥ �� ���� ������ �����Ͽ� ����Ͻÿ�.
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
  
--4. product_id 2�� ��ǰ�� �ȷȴ� ��¥���� ��¥�� �� ���ž��� ���ž� ����(��������)���� �����Ͽ� ����Ͻÿ�.
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
  
--5. ���ž��� ���� ���� ���� �� �� ����Ͻÿ�. (WHERE���� ������� �ʰ�)
select
  user_id
from
  practice
group by
  user_id
order by
  sum(revenue)
limit 1
  
  
 