-- 1. 국가별 최고 레벨을 구하고, 최고 레벨이 100이하면 제외하세요.
select country ,max(level) as max_lv from login
group by country 
having max_lv > 100
order by max_lv

-- 2. 아이템 카테고리별로 가장 돈을 많이 쓴 유저를 구하세요.
with cat as(
select s.item_id, s.userid,sum(s.amount*s.price) as u, ROW_NUMBER() over(PARTITION by mi.category order by sum(s.amount*s.price) desc) as row_num,mi.category 
from sales s inner join meta_item mi on s.item_id =mi.itemid 
group by s.item_id, s.userid  
)
select userid,u,category from cat
where row_num = 1

-- 3. 각 유저의 레벨, 로그인 수, 지출한 금액을 구하세요.
select l.userid,count(*) as lt, max(l.level) as max_lv, s.p
from login l inner join (select userid, sum(amount*price) as p from sales
group by userid) as s on l.userid = s.userid  
group by l.userid
order by l.userid 

-- 4. 국가별로 D+1 Retention을 구하세요.

-- 5. 국가별 Android 유저 수 분포와 ARPPU를 구하세요.
with CA as(
select country,os,count(*) as AndUser from register r
where os = 'Android' 
group by country
),
PU as(
select r.country,count(DISTINCT s.userid) as n,sum(s.amount*s.price) as p 
from sales s inner join register r on s.userid = r.userid
group by r.country
)
select CA.country,CA.AndUser,round(PU.p*1.0/PU.n*1.0,2) as ARPPU
from CA inner join PU on CA.country = PU.country 

-- 6. Continent에 따른 월별 MAU를 구하고 매출과 PASS 상품의 매출을 구하세요.(***)
with MAU as(
select mc.continent,SUBSTRING(logtime,1,7) as date, count(DISTINCT userid) as MAU 
from login l inner join meta_country mc on l.country = mc.country_code 
group by mc.continent,SUBSTRING(logtime,1,7)
),
s as(
select mc.continent,SUBSTRING(log_time,1,7) as date, sum(amount*price) as sale
from sales s inner join register r on s.userid = r.userid inner join meta_country mc on r.country =mc.country_code
where EXISTS (select * from meta_item mi 
              where category = 'pass' and s.item_id = mi.itemid)
group by mc.continent,SUBSTRING(log_time,1,7) 
)
select MAU.continent, MAU.date, MAU.MAU,s.sale from MAU left join s on MAU.continent = s.continent and MAU.date = s.date

