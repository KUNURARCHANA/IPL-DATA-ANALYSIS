/*creating a ipl ball table*/
create table ipl_ball(
id integer,
inning int,
over int,
ball int,
batsman varchar,
non_striker varchar,
bowler varchar,
batsman_runs int,
extra_runs int,
total_runs int,
is_wicket int,
dismissal_kind varchar,
player_dismissed varchar,
fielder  varchar,
extras_type varchar,
batting_team varchar,
bowling_team varchar);

/* copying the data into the ipl ball table*/
COPY IPL_BALL FROM 'C:/Program Files/PostgreSQL/17/data/Files/IPL Dataset/IPL_Ball.csv'
DELIMITER ','
CSV HEADER;
select * From IPL_BALL;
/*Creating ipl matches table*/
create table ipl_matches(
id int,
city varchar,
date date,
player_of_match varchar,
venue varchar,
neutral_venue int,
team1 varchar,
team2 varchar,
toss_winner varchar,
toss_decision varchar,
winner varchar,
result varchar,
result_margin int,
eliminator varchar,
method varchar,
umpire1 varchar,
umpire2 varchar);
/*copying data into iplmatches table*/
copy ipl_matches from'C:\Program Files\PostgreSQL\17\data\FILES\IPL Dataset\IPL_matches.csv'
delimiter ','
csv header;

SELECT * From IPL_MATCHES;

/*Query to get the top 10 Aggressive Batsman with high Strike Rate*/
select * 
from (select batsman,
	  sum(batsman_runs) as total_runs_scored,
	  count(ball) as balls_faced,
	  (sum(batsman_runs)::decimal/count(ball))*100 as strike_rate
from ipl_ball
where extras_type!='wides'
group by batsman) as a 
where a.balls_faced>=500
order by a.strike_rate desc
limit 10;

/*query to get the top 10 anchor batsmen with good average and played 2 seasons*/
select * from
(select a.batsman,
		sum(a.batsman_runs) as total_runs,
		sum(a.is_wicket) as no_of_times_dimissed,
		count(distinct(extract(year from b.date))) as season,
		(sum(a.batsman_runs)*1.0/sum(a.is_wicket)) as average
from ipl_ball as a
left join ipl_matches as b
on a.id=b.id
group by a.batsman ) as d
where d.season>2
order by d.average desc
limit 10;

/*QUERY TO GET TOP 10 HARD-HITTING BATSMAN WHO SCORED MORE RUNS IN BOUNDARIES AND PLAYED 2 IPL SEASONS */
select * from
( select a.batsman,
		sum(a.batsman_runs) as batsman_total_runs,
		sum(a.total_runs) as total_runs,
		count(distinct(extract(year from b.date))) as season,
		(sum(case when total_runs >=4 then batsman_runs  else 0 end)* 100/sum(batsman_runs)*1.0) as boundary_percentage
from ipl_ball as a
left join ipl_matches as b
on a.id=b.id
group by a.batsman) as d
where d.season>2
order by d.boundary_percentage desc
limit 10;

/* query  to get the top 10  economical bowlers with good economy and bowled atleast 500 balls in ipl*/
select * from
(select bowler,
		sum(total_runs) as total_runs_given,
		(count(over)/6) as total_over_bowled,
		count(ball) as total_balls,
		(sum(total_runs*1.0)/(count(over)/6)) as economy
from ipl_ball
 group by bowler) as a
where a.total_balls>=500
order by a.economy desc
limit 10;

/*query to get the top 10 wicket-taking bowlers with good strike rate and bowled atlest 500 balls in ipl*/
select bowler,
		count(ball) as total_balls_bowled,
		sum(is_wicket) as total_wicket_taken,
		((count(ball)*1.0)/sum(is_wicket)) as strike_rate
from ipl_ball
where not dismissal_kind in('run out','retired hurt','obstructing the field')
group by bowler
having count(ball)>500
order  by strike_rate desc
limit 10;

/*query to get the top 10 all rounders with best batting as well as bowling strike rate who has faced atleast 500 balls and bowled minimum 300 balls in ipl*/
select a.*,b.* from
(select batsman as player,
	  sum(batsman_runs) as total_runs_scored,
	  count(ball) as balls_faced,
	  (sum(batsman_runs)::decimal/count(ball))*100 
	as batting_strike_rate
from ipl_ball
where extras_type!='wides'
group by batsman  having count(ball)>=500
order by batting_strike_rate desc) as a
inner join (select bowler as player,
		count(ball) as total_balls_bowled,
		sum(is_wicket) as total_wicket_taken,
		((count(ball)*1.0)/sum(is_wicket)) as bowling_strike_rate
from ipl_ball
where not dismissal_kind in('run out','retired hurt','obstructing the field')
group by bowler having count(ball)>300 order  by bowling_strike_rate desc)  as b
on a.player=b.player
order by batting_strike_rate desc,
bowling_strike_rate desc   limit 10;


/* Additonal Queries*/
--1
select count(distinct(city)) from ipl_matches;

--2
create table deliveries_v02 as(
select * ,
	(case when total_runs>=4 then 'boundary'
	when total_runs=0 then 'dot'
	else 'other' end) as ball_result
from ipl_ball);

--3
select count(case when ball_result ='boundary' then 1 end) as total_boundary,
count(case when ball_result ='dot' then 1 end) as total_dot_balls
from deliveries_v02;

--4
select distinct batting_team,
count (case when ball_result = 'boundary' then 1 end) as boundary_scored
from deliveries_v02
group by batting_team
order by boundary_scored desc;

--5
select distinct bowling_team,
count(case when ball_result = 'dot' then 1 end) as 
No_of_dot_balls
from deliveries_v02
group by bowling_team
order by No_of_dot_balls desc;

--6
select DISTINCT DISMISSAL_KIND, count(case when dismissal_kind != 'NA' then 1 end) as total_dismissal
from deliveries_v02
Group By DISMISSAL_KIND;

--7
select bowler,sum(extra_runs) as max_extra_runs from deliveries_v02
group by bowler
order by max_extra_runs desc
limit 5;

--8
create table deliveries_v03 as
(select a.*,b.venue,b.date as match_date
from deliveries_v02 as a
left join ipl_matches as b
on a.id=b.id);
select * from deliveries_v03;

--9
select venue,count(total_runs) as total_runs_in_venue
from deliveries_v03
group by venue
order by count(total_runs) desc;

--10
select distinct extract(year from match_date) as year,
count(total_runs) as total_runs
from deliveries_v03
where venue='Eden Gardens'
group by year
order by  count(total_runs) desc;










