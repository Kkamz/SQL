-- 1. 날짜별접근 데이터를 집계하는 쿼리 
select substring(stamp,1,10) as dt,
-- 쿠키 계산
	count(distinct long_session) as access_users,
-- 방문 횟수 계산
	count(distinct short_session) as access_count,
-- 페이지 뷰 계산
	count(*) as page_view,
-- 1인당 페이지 뷰 수 
	1.0 * count(*) / nullif(count(distinct long_session),0) as pv_per_user
from access_log_14
group by 1
order by 1

-- 2. URL별로 집계하는 쿼리 
select url,
	count(distinct short_session) as access_count,
	count(distinct long_session) as access_users,
	count(*) as page_view
from access_log_14 al 
group by 1

-- 3. 경로별로 집계하는 쿼리 
with access_log_with_path as(
-- URL에서 경로 추출  
	select *, substring(url from '//[^/]+([^?#]+)') as url_path
	from access_log_14 al 
)
select url_path,
		count(distinct short_session) as access_count,
		count(distinct long_session) as access_users,
		count(*) as page_view
from access_log_with_path
group by 1

-- 4. URP에 의미를 부여해서 집계하는 쿼리
with access_log_with_path as(
-- URL에서 경로 추출  
	select *, substring(url from '//[^/]+([^?#]+)') as url_path
	from access_log_14 al 
),
access_log_with_split_path as (
	-- 경로의 첫번째 요소와 두번째 요소 추
	select *,
			split_part(url_path,'/',2) as path1,
			split_part(url_path,'/',3) as path2
	from access_log_with_path
),
access_log_with_page_name as (
	--경로를 슬래시로 분할하고, 조건에 따라 페이지 이름 붙이기 
	select *,
		case when path1 ='list' then 
									case when path2 = 'newly' then 'newly_list'
									else 'category_list'
									end 
		-- 이외의 경로를 그대로 사용 
		else url_path 
		end as page_name
	from access_log_with_split_path 
)
select page_name,
	count(distinct short_session) as access_count,
	count(distinct long_session) as access_users,
	count(*) as page_view
from access_log_with_page_name
group by 1
order by 1

-- 5. 유입원별로 방문횟수를 집계하는 쿼리 
with access_log_with_parse_info as( 
-- 유입원 정보 추출
select *,
		substring(url from 'https?://([^/]*)') as url_domain,
		substring(url from 'utm_source=([^&]*)') as url_utm_source,
		substring(url from 'utm_medium=([^&]*)') as url_utm_medium,
		substring(referrer from 'https?://([^/]*)') as referrer_domain
from access_log_14 al 
),
access_log_with_via_info as (
	select *,
			row_number() over(order by stamp) as log_id,
			case when url_utm_source  <> '' and url_utm_medium <> ''
				then concat(url_utm_source,'-',url_utm_medium)
			when referrer_domain in ('search.yahoo.co.jp','www.google.co.jp') then 'search'
			when referrer_domain in ('twitter.com','www.facebook.com') then 'social'
			else 'other'
			-- else referrer_domai로 변경하면 도메인별로 집계 가
			end as via
	from access_log_with_parse_info
	where coalesce(referrer_domain,'') not in ('', url_domain)
)
select via, count(1) as access_count
from access_log_with_via_info
group by 1
order by 1

-- 6. 각 방문에서 구매한 비율(CVR)을 집계하는 쿼리 
with access_log_with_parse_info as( 
-- 유입원 정보 추출
select *,
		substring(url from 'https?://([^/]*)') as url_domain,
		substring(url from 'utm_source=([^&]*)') as url_utm_source,
		substring(url from 'utm_medium=([^&]*)') as url_utm_medium,
		substring(referrer from 'https?://([^/]*)') as referrer_domain
from access_log_14 al 
),
access_log_with_via_info as (
	select *,
			row_number() over(order by stamp) as log_id,
			case when url_utm_source  <> '' and url_utm_medium <> ''
				then concat(url_utm_source,'-',url_utm_medium)
			when referrer_domain in ('search.yahoo.co.jp','www.google.co.jp') then 'search'
			when referrer_domain in ('twitter.com','www.facebook.com') then 'social'
			else 'other'
			-- else referrer_domai로 변경하면 도메인별로 집계 가
			end as via
	from access_log_with_parse_info
	where coalesce(referrer_domain,'') not in ('', url_domain)
),
access_log_with_purchase_amount as (
	select a.log_id, a.via,
			sum(case when p.stamp::date between a.stamp::date and a.stamp::date + '1 day'::interval
				then amount end) as amount
	from access_log_with_via_info as a left outer join purchase_log_14 as p on a.long_session = p.long_session
	group by 1,2
)
select via,
		count(1) as via_count,
		count(amount) as conversions,
		avg(100.0 * sign(coalesce(amount,0))) as cvr,
		sum(coalesce(amount,0)) as amount,
		avg(1.0 * coalesce(amount,0)) as avg_amount
from access_log_with_purchase_amount
group by 1
order by cvr desc

-- 7. 요일/시간대별 방문자 수를 집계하는 쿼리 
with access_log_with_dow as ( 
	select stamp,
	-- 일요일(0) 부터 토요일(6)까지 요일 번호 추출
	date_part('dow',stamp::timestamp) as dow,
	-- 00:00:00부터의 경과시간을 초 단위로 계산 
	cast(substring(stamp,12,2) as int) * 60 * 60 +
	cast(substring(stamp,15,2) as int) * 60 + 
	cast(substring(stamp,18,2) as int) as whole_seconds,
	-- 시간 간격 정하기
	-- ex) 30분(1800)로 지정 
	30*60 as interval_seconds
	from access_log_14
),
access_log_with_floor_seconds as (
	select stamp, dow,
	-- 00:00:00부터의 경과시간을 interval_seconds로 나누기 
	cast((floor(whole_seconds/interval_seconds)* interval_seconds) as int) as floor_seconds
	from access_log_with_dow
),
access_log_with_index as( 
	select stamp, dow,
	-- 초를 다시 타임스탬프 형식으로 변환 
	lpad(floor(floor_seconds / (60*60))::text,2,'0')||':'
	|| lpad(floor(floor_seconds % (60*60)/60)::text,2,'0') ||':'
	|| lpad(floor(floor_seconds % 60)::text,2,'0') as index_time
	from access_log_with_floor_seconds
)
select index_time,
		count(case dow when 0 then 1 end) as sun,
		count(case dow when 1 then 2 end) as mon,
		count(case dow when 2 then 3 end) as tue,
		count(case dow when 3 then 4 end) as wed,
		count(case dow when 4 then 5 end) as thu,
		count(case dow when 5 then 6 end) as fir,
		count(case dow when 6 then 7 end) as sat
from access_log_with_index
group by 1
order by 1