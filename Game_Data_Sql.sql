-- 1. 국가별 유저들이 1레벨을 올리는 데에 평균 몇번 로그인했는지 구하세
with group_country as(
select 
  count(DISTINCT userid) as country_user,count(*)*1.0/max(level)*1.0 as country_lv, country  
from 
  login l
group by 
  country
)
select country_lv/country_user, country from group_country  

-- 2.아이템별 일일 최대/평균 매출, 최대/평균 PU를 구하시오.
with mean_sale as(
select item_id, sum(amount*price)as sale,count(DISTINCT SUBSTRING(log_time,6,6)) as cnt_day from sales
group by item_id
order by item_id
),
PU as(
select item_id ,SUBSTRING(log_time,6,6) as day, count(DISTINCT userid) as PU,ROW_NUMBER() over(PARTITION by item_id order by count(DISTINCT userid) desc)as rank_PU from sales
group by day, item_id 
order by item_id 
),
max_PU as(
select * from PU
where rank_PU = 1
),
cnt_PU as(
SELECT item_id ,sum(PU)as sumPU,count(day) as cnt from PU
group by item_id
)
select ds.item_id,ds.sale as max_sale, ds.sale/ms.cnt_day as mean_sale, max_PU.PU as max_PU, cnt_PU.sumPU*1.0/cnt_PU.cnt*1.0 as mean_PU
from (select 
	item_id ,SUBSTRING(log_time,6,6) as day, sum(amount*price)as sale, ROW_NUMBER() over(PARTITION by item_id order by sum(amount*price) desc) as rownum 
	from sales
	group by item_id,day
	order by item_id, sale desc)as ds inner join mean_sale as ms on ds.item_id = ms.item_id inner join max_PU on ms.item_id = max_PU.item_id inner join cnt_PU on max_PU.item_id =cnt_PU.item_id
where rownum = 1

-- 3.매일 7번쨰로 로그인한 유저에게 보상을 주고자 합니다. 일별 7번째 로그인 유저를 구해주세요
with login_time as(
select SUBSTRING(logtime,6,6) as day ,*,ROW_NUMBER() over(PARTITION by SUBSTRING(logtime,6,6) order by SUBSTRING(logtime,12,8)) as row_num from login l
group by day, userid 
order by day
)
select day,userid,logtime,country,os from login_time
where row_num = 7

-- 4.레벨 10, 레벨 30, 레벨 50에 2번째 도달한 유저의 아이디를 구하세요.
with find_user as(
select *,ROW_NUMBER() over(PARTITION by level order by logtime)as row_num from login 
where level in(10,30,50)
group by level, userid
)
select userid,logtime,country,os,level from find_user
where row_num = 2

-- 5. 아이템별 지출금액이 가장 큰 유저와 그 금액을 구하세요. 
with VIP as(
select *, (amount * price) as sale, ROW_NUMBER() over(PARTITION by item_id order by amount*price desc) as row_num from sales
group by item_id, userid
)
select userid,sale
from VIP 
where row_num = 1
order by sale desc

-- 6.레벨 100에 가장 먼저 도달한 10명의 플레이어의 일일 평균 지출금액을 구하세요
select l.userid,l.level,p.total_sale/p.day from login l inner join 
(select *,sum(amount*price)as total_sale,count(DISTINCT SUBSTRING(log_time,1,10)) as day 
from sales 
group by userid) as p on l.userid = p.userid
where level in (100)
group by l.userid
order by logtime
limit 10

-- 7. 국가별 OS에 따른 유저 수를 구하고, 이를 순위로 나타내세요.
select country,os,count(*) as user_num, DENSE_RANK() over(order by count(*) desc) as dencerank from register
group by country, os
order by user_num desc
