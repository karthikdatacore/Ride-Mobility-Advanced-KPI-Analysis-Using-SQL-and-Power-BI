create database advanced_riding_share;
use advanced_riding_share;


-- 1. Create Vehicles Table
CREATE TABLE vehicles (
    vehicle_id int primary key,
    make varchar(100),
    model varchar(100),
    vehicle_Type varchar(100),
    Powertrain_Category varchar(100),
    capacity int
);
select* from vehicles;

-- 2. Create Drivers Table
CREATE TABLE drivers (
    driver_id int primary key,
    name varchar(100),
    vehicle_id int,
    rating decimal(3,2),
    total_rides int,
    available varchar(10),
    foreign key (vehicle_id) references vehicles(vehicle_id)
);


select* from drivers;
-- 3. Create Users Table
CREATE TABLE users (
    user_id int primary key,
    name varchar(100),
    email varchar(100),
	phone varchar(50),
    registration_date datetime, 
    age int,
    gender varchar(50),
    location varchar(100)
);

select*from users;
select count(user_id) from users;


-- 4. Create Rides Table
CREATE TABLE rides (
    ride_id int primary key,
    user_id int,
    start_location varchar(100),
    end_location varchar(100),
    ride_date date, 
    ride_start_time time,  
    ride_end_time time,    
    distance_km DECIMAL(6,2),
    fare_amount DECIMAL(8,2),
    driver_id INT
);

select* from rides;
drop table rides;

-- 5. Create Ratings Table
CREATE TABLE ratings (
    rating_id INT PRIMARY KEY,
    ride_id INT,
    user_id INT,
    rating_value INT,
    comments TEXT,
    rating_date DATETIME);
    
    select* from ratings;
    
create table calendar(
date_id Date primary key,
year_num int,
month_num int,
month_name varchar(10),
quarter int);

insert into calendar (date_id, year_num, month_num, month_name,quarter)
with calendar as(
    select CAST('2024-01-01' as date) as d
    union all
    select date_add(d, interval 1 day)
    from calendar
    where d < '2024-10-04'
)
select
    d as date_id,
    year(d) as year_num,
    month(d) as month_num,
    date_format(d, '%b') as month_name,
    Quarter(d) as quarter_num
from calendar;

select* from calendar;

    
select ride_date from ride_sharing_dataset order by ride_date desc;
    CREATE TABLE ride_sharing_dataset AS
SELECT 
    r.ride_id,
    r.ride_date,
    r.ride_start_time,
    r.ride_end_time,
    r.distance_km,
    r.fare_amount,
    r.start_location,
    r.end_location,
    u.user_id,
    u.name AS passenger_name,
    u.age AS passenger_age,
    u.gender AS passenger_gender,
    d.driver_id,
    d.name AS driver_name,
    d.rating AS driver_historical_score,
    v.vehicle_id,
    v.make AS vehicle_brand,
    v.model AS vehicle_model,
    v.capacity AS vehicle_seating_capacity,
    rat.rating_value AS trip_rating_given,
    rat.comments AS trip_feedback_text
from rides r
left join users u on r.user_id = u.user_id
left join drivers d on r.driver_id = d.driver_id
left join vehicles v on d.vehicle_id = v.vehicle_id
left join ratings rat on r.ride_id = rat.ride_id
where r.ride_id is not null;

drop table ride_sharing_dataset;

select * from ride_sharing_dataset ;
select * from ride_sharing_dataset where ride_id=50000;

-- KPI standouts 

-- General KPI
-- 1) Total Ride Records 
select count(*) as Total_Ride_Records from ride_sharing_dataset;
select count(ride_id) as Total_ride from ride_sharing_dataset;
-- 2) Total users who used ride out of 10000)
select count(user_id) from users;
select count(distinct(user_id)) from ride_sharing_dataset;

-- 3)Total drivers with car who were active in days (out of 300 drivers) 
select count(driver_id) from drivers;
select count(distinct(driver_id))from ride_sharing_dataset;

-- 4)Total Revenue Amount 
select sum(fare_amount) as Total_Revenue from ride_sharing_dataset;

-- 5) Average Revenue Amount
select avg(fare_amount) as avg_Revenue from ride_sharing_dataset;

-- 6) Year wise different
select distinct(year(ride_date)) from ride_sharing_dataset;

-- 7) month wise different 
select count(distinct(month(ride_date))) from ride_sharing_dataset;
create table monthly_revenue_2024 as select distinct(month(ride_date)) as Months, sum(fare_amount) as Monthly_wise_Fare_amount_revenue from ride_sharing_dataset group by month(ride_date) order by months;

create table monthly_revenue_2024 AS
select 
c.month_name as Months, 
sum(r.fare_amount) as Monthly_wise_Fare_amount_revenue 
from ride_sharing_dataset r
join calendar c 
on cast(r.ride_date AS DATE) = c.date_id
group by c.month_name, c.month_num
order by c.month_num;

-- 8) driver KPI

-- Total Rides per Driver
select driver_id,driver_name,
count(*) as total_rides from ride_sharing_dataset group by driver_id,driver_name order by total_rides desc;

-- Total Revenue
select driver_id,driver_name,
sum(fare_amount) as total_Revenue from ride_sharing_dataset group by driver_id,driver_name order by total_Revenue desc;

-- Average rating
select driver_id,driver_name,avg(trip_rating_given) as avg_rating 
from ride_sharing_dataset group by driver_id,driver_name order by avg_rating desc;

-- Average Revenue per Ride
select driver_id,driver_name,avg(fare_amount) as avg_revenue_per_ride
from ride_sharing_dataset 
group by driver_id,driver_name; 

-- Peak Hour Performance
SELECT 
driver_id,
driver_name,
min(ride_start_time) as start_hour,
max(ride_end_time) as end_hour
from ride_sharing_dataset
group by driver_id,driver_name;

-- More time Work drivers
select *
from (
select
driver_id,driver_name,
count(ride_id) as total_ride,
sum(fare_amount) as total_revenue,
avg(fare_amount) as Total_avg,
dense_rank() over (order by count(ride_id) desc,sum(fare_amount) desc) AS rank_no
from ride_sharing_dataset
group by driver_id,driver_name
) ranked
where rank_no <= 5;

-- Top 5 driver rating
select *
from (
select
driver_id,driver_name,
count(ride_id) as total_ride,
sum(fare_amount) as total_revenue,
avg(trip_rating_given) as Total_avg,
dense_rank() over (order by avg(trip_rating_given) desc,count(ride_id) desc,sum(fare_amount) desc) AS rank_no
from ride_sharing_dataset
group by driver_id,driver_name
) ranked
where rank_no <= 5;

-- Top 5 Drivers Performance 
select *
from (
select
driver_id,
driver_name,
count(ride_id) as total_rides,
sum(fare_amount) as total_revenue,
avg(trip_rating_given) as avg_rating,
dense_rank() over (
order by avg(trip_rating_given) desc,sum(fare_amount) desc,count(ride_id) desc) as rank_no
from ride_sharing_dataset
group by driver_id, driver_name
) ranked
where rank_no <= 5;

-- Users KPI
select month(ride_date) as month ,count(distinct user_id)  as active_users_through_months
from ride_sharing_dataset group by month;

-- User Revenue KPI 
-- Revenue per User
select user_id,passenger_name,sum(fare_amount) as total_spent
from ride_sharing_dataset
group by user_id,passenger_name;
-- Average Revenue per User


-- Repeat Users
select user_id,passenger_name,
count(*) as Total_rides
from ride_sharing_dataset 
group by user_id,passenger_name having count(*)>1;

-- Churn Type User Active
select user_id,passenger_name 
from ride_sharing_dataset
group by user_id,passenger_name having max(ride_date)< current_date - interval 30 day; 

-- User Satisfication 
select user_id,passenger_name,avg(trip_rating_given) as avg_rating_given
from ride_sharing_dataset group by user_id,passenger_name;

select count(*) as churn_user_count
from (select user_id,passenger_name 
from ride_sharing_dataset
group by user_id,passenger_name having max(ride_date)< current_date - interval 200 day)churn_users;

-- ride per city per user
select *
from (
select
start_location,
end_location,
count(*) as rides
from ride_sharing_dataset
group by start_location,end_location having count(*)> 1 )as Overall_Ride_location;


select 
round(sum(fare_amount),2) as total_gross_revenue,
round(avg(fare_amount),2) as avg_fare_per_ride,
round(sum(fare_amount)/sum(distance_km),2) as revenue_per_km
from ride_sharing_dataset where distance_km>0;


with ride_durations as (
    select
driver_id,
driver_name,
distance_km,
timestampdiff(minute, ride_start_time, ride_end_time) / 60 AS hours_incorrect,
CONCAT(
FLOOR(TIME_TO_SEC(TIMEDIFF(ride_end_time, ride_start_time)) / 3600), 'h ',
FLOOR((TIME_TO_SEC(TIMEDIFF(ride_end_time, ride_start_time)) % 3600) / 60), 'm'
    ) AS duration_formatted
    
FROM ride_sharing_dataset
WHERE distance_km > 0
  AND ride_start_time IS NOT NULL 
  AND ride_end_time IS NOT NULL
LIMIT 20
)
select 
    count(*) as total_rides_processed,
    round(avg(distance_km),2) as avg_ride_distance_km,
    round(avg(duration_minutes),2) as avg_ride_duration_mins,
    round(avg(distance_km/nullif(duration_hours,0)),2) as avg_fleet_speed_kmh
from ride_durations;

select 
    count(distinct driver_id) as active_rostered_drivers,
    round(avg(rating),2) as global_driver_score,
    round(sum(case when available='TRUE' or available='1' then 1 else 0 end)*100.0/count(*),1) as driver_supply_ratio_pct,
    round((select count(distinct vehicle_id) from drivers)*100.0/(select count(*) from vehicles),1) as fleet_utilization_pct
from driver;
