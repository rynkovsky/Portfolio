1. В каких городах больше одного аэропорта?

select a.city, count (a.airport_code) 
from airports a
group by a.city
having count (a.airport_code)  > 1

2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

select distinct departure_airport _airport from flights
where aircraft_code = (select a.aircraft_code
from aircrafts a 
order by a."range" desc 
limit 1)

3. Вывести 10 рейсов с максимальным временем задержки вылета

select f.flight_id, (f.actual_departure - f.scheduled_departure) difference 
from flights f
group by f.flight_id
having f.actual_departure is not null
order by difference desc
limit 10

4. Были ли брони, по которым не были получены посадочные талоны?

select t.ticket_no, bp.ticket_no 
from tickets t 
full join boarding_passes bp  on t.ticket_no = bp.ticket_no 
where bp.ticket_no is null

5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.

select f.flight_id, f.aircraft_code,(c.count_seat - c2.count_seat) free_seats, ((c.count_seat - c2.count_seat)*100/c.count_seat) percent, f.departure_airport, f.actual_departure,
sum (c2.count_seat) over (partition by f.departure_airport, date (f.actual_departure) order by f.actual_departure) 
from flights f 
join (select aircraft_code, count (seat_no) count_seat
from seats 
group by aircraft_code) c on c.aircraft_code = f.aircraft_code 
join (select flight_id, count (seat_no) count_seat
from boarding_passes
group by flight_id ) c2 on c2.flight_id = f.flight_id
order by  f.departure_airport, date (f.actual_departure)

6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.

select distinct f.aircraft_code, count (f.flight_id), concat (round ((count (f.flight_id)::numeric * 100 / (select count (flight_id) 
from flights)), 2), '%') as percent_af
from flights f 
group by f.aircraft_code 
order by f.aircraft_code

7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

with cte as (select f.flight_id, a.airport_name, a.city 
			from flights f join airports a on a.airport_code = f.arrival_airport 
			group by f.flight_id, a.airport_name, a.city 
			order by f.flight_id),
cte2 as (select distinct tf.flight_id, tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Business' 
	order by tf.flight_id),
cte3 as (select distinct tf.flight_id, tf.fare_conditions, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Economy' 
	order by tf.flight_id)
select cte2.flight_id, cte2.fare_conditions, cte2.amount, cte.airport_name, cte.city 
from cte2 
join cte3 on cte3.flight_id = cte2.flight_id
join cte on cte.flight_id = cte2.flight_id
where cte3.amount > cte2.amount
order by cte2.flight_id

8. Между какими городами нет прямых рейсов?

create view task21 as 
	select distinct (a.city) c, (a2.city) c2
	from flights f 
	join airports a on a.airport_code = f.departure_airport 
	join airports a2 on a2.airport_code = f.arrival_airport

create view task22 as 
	select (a.city) c, (a2.city) c2
	from airports a, airports a2
 
select c, c2
from task22
where c != c2
except 
select c, c2
from task21

9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы.
	
with cte4 as (select distinct f.departure_airport, f.arrival_airport, (acos (sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude - a2.longitude)) * 6371) L, 
	a3."range" 
	from flights f 
	join airports a on a.airport_code = f.departure_airport 
	join airports a2 on a2.airport_code = f.arrival_airport	
	join aircrafts a3 on a3.aircraft_code = f.aircraft_code) 
select cte4.departure_airport, cte4.arrival_airport,cte4.L, cte4."range",
	(case
		when cte4.L < cte4."range" then 'долетит'
		else 'не долетит'
	end) comprasion
from cte4


























