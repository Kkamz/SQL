select * from sales

select * from login

--1. �ѱ����� ���� ���� �ȸ� ��ǰ�� ���Ͻÿ�.
select 
  item, SUM(dia_amount*buy_count) as total
from 
  sales
WHERE
  Country ='Korea'
group by
  item
order by
  total desc
  
--2. ���� A�� B�� ��¥�� �ְ� �޼� ������ ��¥ �� ���� ������ �����Ͻÿ�.
select
  date, ID, max(level) as max_Lv
FROM
  login
WHERE
  ID = 'A' or ID = 'B'
group by
  date, ID
order BY
  date, ID

--3. ������ �� ���� ������ ����Ͻÿ�.(���� ������ ���� ������)
select
  Country, sum(dia_amount*buy_count) as total
from
  sales
group by 
  Country
order by 
  total desc

--4. ��¥���� ���� ���� �� ��� ���� �ݾ��� ����Ͻÿ�. (��¥ ������)
select 
  date, ID, avg(dia_amount*buy_count) as avg
FROM
  sales
group by
  date, ID
order by
  date
  
--5. ���� �� ��� ���� Ƚ���� ���� ���� ��¥�� ����Ͻÿ�.  
select
  ID, date, max(login_count)
FROM
  (select 
     ID, date, count(date) as login_count
   from
     login
   group by
     ID, date) as l
GROUP By
  ID
 
  --6. ���� ��� ��(���� �� ���� ������ �ְ� ������ ����)�� ���� �۾Ҵ� ������ ����Ͻÿ�.
select 
  ID, max(level)-min(level) as gap
from 
  login
group by 
  ID
order by 
  gap
limit 1

--7. �Ϻ��� ������ ����, PU, ��� ���� Ƚ���� ��¥ �� ���� �������� �����Ͻÿ�.(��¥�� �������, �� ��¥ �ȿ��� ������ ū ��������)
select 
  date as DATE, Country ,sum(dia_amount*buy_count) as Sale, count(DISTINCT ID) as PU, avg(buy_count) as AVG
from
  sales
GROUP BY 
  DATE, Country
order by 
  DATE, Sale ASC