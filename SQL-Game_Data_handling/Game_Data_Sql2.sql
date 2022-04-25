-- 1. 국가별 매출을 구하세요(매출이 없는 국가도 포함)
select r.country,sum(amount*price) as total_sale  from sales s inner join register r on s.userid = r.userid
group by r.country
order by total_sale 

-- 2. 구매유저와 비구매유저의 평균 로그인 횟수와 레벨을 구하세요(소수점 2자리까지)
with no_pay as(
select l.userid, count(*) as login_time, max(level) as lv from login l
where not EXISTS(select userid from sales s 
where l.userid = s.userid)
group by userid
),
pay as(
select userid, count(*) as login_time, max(level) as lv from login l
where EXISTS(select userid from sales s 
where l.userid = s.userid)
group by userid
),
count_np as(
select count(DISTINCT userid) as np from login l
where not EXISTS(select userid from sales s 
where l.userid = s.userid)
),
count_p as (
select count(DISTINCT userid) as p from login l
where EXISTS(select userid from sales s 
where l.userid = s.userid)
)
select 
round((sum(np.login_time)*1.0/cnnp.np*1.0),2) as np_lgt, round((sum(np.lv)*1.0/cnnp.np*1.0),2) as np_lv, round((sum(p.login_time)*1.0/cnp.p*1.0),2) as p_lgt, round((sum(p.login_time)*1.0/cnp.p*1.0),2) as p_lv
from no_pay as np,pay as p,count_np as cnnp, count_p as cnp

-- 3. 월별 MAU, 매출, PU, PUR, ARPU, ARPPU를 구하세요
with MAU as(
select SUBSTRING(logtime,1,7) as Date, count(DISTINCT userid) as MAU 
from login as l
group by SUBSTRING(logtime,1,7)
),
s as(
select SUBSTRING(log_time,1,7) as Date, sum(amount*price) as sale from sales
group by SUBSTRING(log_time,1,7)
),
PU as(
select SUBSTRING(log_time,1,7) as Date,count(DISTINCT userid) as PU from sales
group by SUBSTRING(log_time,1,7)
)
select MAU.Date, MAU.MAU, s.sale, PU.PU,MAU.MAU/PU.pu as PUR, round(s.sale*1.0/MAU.MAU*1.0,2) as ARPU, round(s.sale*1.0/PU.PU*1.0,2) as ARPPU
from MAU inner join s on MAU.Date = s.date inner join PU on s.date = PU.date

-- 4. meta 테이블을 이용해 server별 일별 DAU를 구하세요.
select mc.server,SUBSTRING(logtime,6,6) as day,count(DISTINCT userid) as DAU 
from login l inner join meta_country mc on l.country = mc.country_code
group by mc.server, SUBSTRING(logtime,6,6)

-- 5. 각 유저의 로그인, 레벨, 매출, 각 순위를 구하시오(단, 매출이 없는 경우 0으로 처리)
WITH Q as(
select l.userid,count(*) lt,max(level) lv,case when p.pay is null then 0 
														when p.pay is not null then p.pay
														end as pay
from login l left join (select userid,sum(amount*price) as pay from sales
						group by userid) as p on l.userid = p.userid
group by l.userid
)
select userid,lt,RANK() over(order by lt desc) as login_rank,lv,RANK() over(order by lv desc) as lv_rank,pay,RANK() over(order by pay desc) as pay_rank
from Q
order by userid 

-- 6. 아시아 서버의 유저가 구매한 아이템별 매출과 매출 순위를 구하세요. 
select s.item_id,sum(amount*price) as pay, ROW_NUMBER() over(order by sum(amount*price) desc) as rank from sales s inner join register r on s.userid = r.userid 
where EXISTS (select * from register r
			where EXISTS (select country_code from meta_country mc 
			where continent like "Asia%" and r.country = mc.country_code) and s.userid = r.userid)
group by s.item_id
order by pay desc
