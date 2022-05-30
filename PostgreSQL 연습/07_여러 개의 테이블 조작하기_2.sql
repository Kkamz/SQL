-- 1. 디바이스 ID와 이름의 마스터 테이블을 만드는 쿼리 
with mst_devices as(
	select 1 as device_id, 'pc' as device_name
	union all select 2 as device_id, 'sp' as device_name
	union all select 3 as device_id, 'app' as device_name
	)
select * from mst_devices

-- 2. 의사 테이블을 사용해 코드를 레이블로 변환하는 쿼리
with mst_devices as(
	select 1 as device_id, 'pc' as device_name
	union all select 2 as device_id, 'sp' as device_name
	union all select 3 as device_id, 'app' as device_name
)
select u.user_id, d.device_name
from mst_users as u left join mst_devices as d on u.register_device = d.device_id

-- 3. values 구문을 사용해 동적으로 테이블을 만드는 쿼리 
with mst_devices(device_id,device_name) as(
values (1,'PC'),
		(2,'SP'),
		(3,'app')
)
select * from mst_devices

-- 4. 순번을 가진 유사 테이블을 작성하는 쿼리 
-- generate_series 사용 
with series as (
select generate_series(1,5) as idx  
)
select * from series
