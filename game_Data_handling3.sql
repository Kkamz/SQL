select * from sales

select * from login

--1. 한국에서 가장 많이 팔린 상품을 구하시오.
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
  
--2. 유저 A와 B의 날짜별 최고 달성 레벨을 날짜 및 유저 순서로 정렬하시오.
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

--3. 국가별 총 구매 수량을 출력하시오.(구매 수량이 많은 순서로)
select
  Country, sum(dia_amount*buy_count) as total
from
  sales
group by 
  Country
order by 
  total desc

--4. 날짜별로 구매 유저 당 평균 구매 금액을 출력하시오. (날짜 순서로)
select 
  date, ID, avg(dia_amount*buy_count) as avg
FROM
  sales
group by
  date, ID
order by
  date
  
--5. 유저 당 평균 접속 횟수가 가장 많은 날짜를 출력하시오.  
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
 
  --6. 레벨 상승 폭(유저 당 최저 레벨과 최고 레벨의 차이)이 가장 작았던 유저를 출력하시오.
select 
  ID, max(level)-min(level) as gap
from 
  login
group by 
  ID
order by 
  gap
limit 1

--7. 일별로 국가별 매출, PU, 평균 구매 횟수를 날짜 및 매출 역순으로 정렬하시오.(날짜는 순서대로, 각 날짜 안에서 매출은 큰 순서부터)
select 
  date as DATE, Country ,sum(dia_amount*buy_count) as Sale, count(DISTINCT ID) as PU, avg(buy_count) as AVG
from
  sales
GROUP BY 
  DATE, Country
order by 
  DATE, Sale ASC