select * from login

select * from sales

-- 1. 구매 횟수가 3회 이상이고 로그인 횟수가 30회 이상인 유저의 로그인 횟수와 구매 횟수를 구하세요.
with login_count as 
(
	select 
	  ID, count(date) as login_cnt
	from 
	  login
	group by
	  ID
	having 
	  login_cnt >= 30
	order BY
	  ID
),
sale_count as
(
	select 
	  ID, sum(buy_count) as buy_count
	from
	  sales
	where
	  buy_count  >= 3
	group by
	  ID
	order BY
	  ID
)
select 
  lc.ID,lc.login_cnt ,sc.buy_count
from 
  login_count as lc, sale_count as sc
where
  lc.id = sc.id 

-- 2. 일자별로 국가별 DAU, PUR, ARPU, ARPPU를 구해주세요.	
with DAU as
(
	select count(DISTINCT ID) as AU
	from login
),
PU as
(
	select count(DISTINCT ID) as BU
	from sales
	where buy_count > 0
)
select 
	AU as DAU, 1.0*BU/AU as PUR,sum(dia_amount*buy_count)/AU as ARPU, sum(dia_amount*s.buy_count)/BU as ARPPU
from
	PU, DAU, sales as s 
	
-- 3. 각 국가별 일평균 로그인 횟수를 구하세요.	
with ID_count as
(
	select 
	  ID, count(date) as date_count
	from
	  login
	group by 
	  ID 
),
ID_country AS 
( 
	select 
	  ID, country
	from 
	  sales
	group by 
	  ID
)
select 
  country, avg(date_count)
from 
  ID_count, ID_country
where 
  ID_count.ID = ID_country.ID
group by
  country

-- 4. 역대 누적 금액이 가장 큰 유저를 VIP라고 합시다. 국가별로 이 VIP의 총구매액과 최고도달레벨을 출력해주세요 (총 매출이 가장 높은 국가 순서대로)
WITH Paying as
(
	select
	  ID,dia_amount*buy_count as total_pay, country
	from  
	  sales
	group by
	  ID
),
max_level AS 
(
	SELECT 
	  ID, max(level) as max_LV
	from
	  login
	group by ID
)
select
  country, max(total_pay) as VIP_pay, max_LV
from
  paying, max_level
WHERE
  Paying.ID = max_level.ID
group by
  Country
order by 
  VIP_pay desc
  
-- 5. 50레벨 이상을 고레벨 유저라고 가정할 때, 비구매 유저들의 고레벨 비중과 구매 유저들의 고레벨 비중을 출력해주세요. (비중이란 모수 중 해당 조건충족자 비율)
with high_LV as 
(
	select 
	  ID as high_ID, max(level) as max_LV	
	from
	  login
	group by
	  ID
	having
	  max_LV >= 50
),
pay AS
(
	select 
	 distinct ID as pay_id
	from
	  sales
	order by
	  ID
),
no_pay AS
(
	select 
	  distinct ID as no_pay_ID
	from 
	  login
	except
	select
	  DISTINCT ID
	from
	  sales
),
high_LV_pay as
(
  select 
    count(distinct pay_id) as count_yes
  from
    pay, high_LV
  where
    pay_id = high_ID
),
high_LV_no_pay AS 
(
  select 
    count(distinct no_pay_id) as count_no
  from
    no_pay, high_LV
  where
    no_pay_id = high_ID
),
parameter_ID as
(
	select 
	  count(distinct ID) as total_count
	from
	  login
)
select
  1.0*count_yes/total_count as high_LV_pay_rate, 1.0*count_no/total_count as high_LV_no_pay_rate
from
  high_LV_no_pay, parameter_ID ,high_LV_pay
  
-- 6. 구매 유저와 비구매 유저들이 리텐션에 얼마나 차이가 있는지 알고자 합니다. 구매 유저와 비구매 유저들의 D1 및 D7 잔존율을 날짜 순으로 출력해주세요.
with login_info as
(
	select
	  id, date
	from 
	  login
	group by 1,2
),
pu_npu as
(
	select
	  t1.id, case when pu is null then 'npu' else pu end as pu
	from
	  (select id from login group by 1) t1
	  left join (select id, 'pu' as pu from sales group by 1,2) t2
	  on t1.id = t2.id
),
login_pu_npu as
(
	select
	  t1.id, date, pu
	from 
	  login_info t1
	  left join pu_npu t2	
	  on t1.id = t2.id
),
date_diff as
(
	select
	  t1.id, pu, date, right_date, julianday(right_date)-julianday(date) as date_diff
	from 
	  login_pu_npu t1
	left join (select id, date as right_date from login_pu_npu) t2
	on t1.id = t2.id
	where 
	  right_date >= date
)
select
  date, pu, 1.0*d1 / dau as d1_rr, 1.0*d7/dau as d7_rr
from
(
  select
    date, pu,
    count(distinct id) as dau,
    count(distinct(case when date_diff = 1 then id else null end)) as
    d1,
    count(distinct(case when date_diff = 7 then id else null end)) as d7
  from
    date_diff
  group by 1,2
  order by 1,2
) t

-- 7. 국가별로 가장 매출이 높은 상품 top3를 알고자 합니다. 이 top3 상품을 구매한 아시아(미국 제외) 유저들의 전체 기간 통틀어서 ARPPU와 일평균 접속 횟수 그리고 평균레벨(최고 도달 레벨 기준)를 구하세요.
with asia_top3 as
(
	select 
	  Country, item,ID, sum(dia_amount*buy_count) as paying
	from 
	  sales
	where 
	  country in ('Korea','China','Japan')
	group by 
	  1,2
),
rank_item_each_country AS
(
	select
	  *,rank() over(PARTITION by country order by paying) as rank_item
	from
	  asia_top3
),
country_top3_PU as
(
	select 
	  distinct ID, country, paying
	from 
	  rank_item_each_country
	where 
	  rank_item>=1 and rank_item<=3
),
PU as
(
	select 
	  count(DISTINCT s.ID) as BU
	from 
	  sales as s ,country_top3_PU as c
	where  
	  buy_count > 0 and s.id = c.id
),
login_count_maxlevel as 
(
	select 
	  l.ID, count(date) as login_count, max(level) as max_lv
	from
	  login as l, country_top3_PU as c
	where
	  l.id = c.id
	group by
	  l.id
)
select 
  sum(paying)/BU as ARPPU,avg(login_count),avg(max_lv)
from 
  login_count_maxlevel,PU, country_top3_PU as c 

-- 8. 매일 첫번째, 7번째, 그리고 마지막 로그인한 유저에게 각각 “early_bird",“lucky_seven", “finale" 출석 보상을 주고자 합니다. 각 날짜별로 출석 보상 타입에 따라 해당되는 유저들을 분류해주세요.
with login_order as
(
	select
	  ID,time,Dense_rank() over(partition by date order by time) as lg_order
	from 
	  login
),
reverse_login_order as
(
	select
	  ID,time,Dense_rank() over(partition by date order by time desc) as re_lg_order
	from 
	  login
)
select 
	lg.ID,lg.time,lg_order,case when lg_order = 1 then "early_bird"
  			when lg_order = 7 then "lucky_seven"
  			when re_lg_order = 1 then "finale" end naming
 from 
   login_order as lg , reverse_login_order as rlg
 where
   lg.ID = rlg.ID and lg.time = rlg.time
group by
   lg.time

-- 9. 일평균 레벨업(기간 통틀어서 레벨업 속도가 가장 빠른)이 가장 빠른 유저의 ID, 국가, 총 구매액, 일평균 구매액, 일평균 접속횟수 를 구하세요.
with LV_Date_gap AS 
(
	SELECT
  	  id, JULIANDAY(DATE(max(date)))-JULIANDAY(DATE(min(date))) as date_gap
	from
  	  login
	group by
  	  ID
),
rank_date_gap AS
(
	select
	  *, rank() over(order by date_gap) as rank
	from 
	  LV_Date_gap
),
rank1_user as
(
	select 
	  *
	FROM 
	  rank_date_gap
	where 
	  rank = 1 
),
total_pay_rk1 as 
(
 	 select 
   	   s.ID, country, sum(dia_amount*buy_count) as paying
 	 from
	   sales as s, rank1_user as rg
	 where
	   s.id = rg.id
),
login_count_rk1 as
(
	select 
	  l.ID,count(*) as login_cnt
	from 
	  login as l,rank1_user as rg
	WHERE 
	  l.id = rg.id
	 group by 
	   l.id
)
select 
  l.id, country, paying, paying/date_gap as avg_daily_pay, login_cnt/date_gap as avg_daily_login_count
from 
  login_count_rk1 as l , total_pay_rk1 as t, rank1_user as ru

-- 10. 레벨 30 구간에 두번째로 도달한 유저의 아이디를 구하고, 해당 유저가 30 구간에 진입한 시점 이후의 총 구매액을 구하세요(진입 당일 제외).  
with lv30 AS 
(
	select
	  *, rank() over(order by time) as date_LV30
	from
	  login
	where 
	  level > 29
	group by 
	  ID
),
sum_amount AS 
(
	select 
	  s.ID, sum(dia_amount*buy_count) as total_pay
	FROM 
	  sales as s, lv30 as l
	where
	  l.ID = s.ID and s.date > l.date
	group by
	  l.ID
)
select
  l.ID, total_pay
from
  lv30 as l , sum_amount as s
where
  l.ID = s.ID and date_LV30 = 2
group by
  l.ID
  select
  
-- 11. 구매액이 가장 큰 유저와 구매액이 가장 적은 유저 간의 기간 통틀어 최고도달 레벨의 차이와 올린 레벨량의 차이를 구하세요.
with paying_user as
(
	select 
	  ID, sum(dia_amount*buy_count) as paying
	from 
	  sales
	group by 
	  1
),
rank_paying as
(
	select 
	  *, rank() over(order by paying desc) as rank_pay
	FROM
	  paying_user
),
min_rank as
(
	select 
	  ID, max(rank_pay)
	FROM
	  rank_paying
),
top_rank as
(
	select 
	  ID, min(rank_pay)
	FROM
	  rank_paying
),
incre_lv as
(
	select
	  l.ID, max(level)-min(level) as incre
	from 
	  login as l , min_rank as m , top_rank as t
	where
	  l.id = m.id or l.id=t.id
	group by
	  l.id
),
max_lv as
(
	select
	  l.ID, max(level) as maxlv
	from 
	  login as l , min_rank as m , top_rank as t
	where
	  l.id = m.id or l.id=t.id
	group by 
	  l.ID
)
select max(maxlv)-min(maxlv) as maxlv_gap , max(incre)-min(incre) as increlv_gap
from max_lv,incre_lv

/* 12. 매출 규모에 따른 유저들의 레벨 분포를 알고자 합니다. 최고도달 레벨 기준으로 레벨 구간을 10씩 나눴을 때(~9, 10~19, 20~29, …), 
	    국가별로 유저수가 두번째로 많은 레벨 구간과 해당 레벨 구간의 PUR, ARPPU 도 함께 구해주세요.*/
with lv_group as
(
	select
	  id, floor(max_lv/10)*10 as lv_group
	from
	(
	select
	  id, max(level) as max_lv
	from
	  login
	group by 1
	) t
),
join_df as
(
	select
	  country, t1.id, revenue, lv_group
	from	
	(
	select
	  country, id, sum(dia_amount*buy_count) as revenue
	from
	  sales
	group by 1,2
	) t1
	left join lv_group t2
	on t1.id = t2.id
)
select
  country, lv_group, count(distinct id) as pu, sum(revenue) as revenue
from 
  join_df
group by 1,2
