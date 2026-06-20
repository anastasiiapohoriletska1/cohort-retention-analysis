-- Завдання 1.1-1.3
SELECT * FROM project.cohort_users_raw 
LIMIT 10; 

SELECT * from project.cohort_events_raw
LIMIT 10;


-- Завдання 1.4-1.5

-- очищення дат у cohort_users_raw
with cleaned as (
	select *, replace(replace(split_part(trim(signup_datetime),' ', 1), '/', '.'), '-', '.') as cleaned_date
	from project.cohort_users_raw)
select *,
	case 
		when length(split_part(cleaned_date, '.', 3)) = 4
			then to_date(cleaned_date, 'dd.mm.yyyy')
		when length(split_part(cleaned_date, '.', 3)) = 2
			then to_date(cleaned_date, 'dd.mm.yy')
		else null
	end as signup_datetime
from cleaned

-- очищення дат у cohort_events_raw
with cleaned as (
	select *, replace(replace(split_part(trim(event_datetime),' ', 1), '/', '.'), '-', '.') as cleaned_date
	from project.cohort_events_raw)
select *, 
	case 
		when length(split_part(cleaned_date, '.', 3)) = 4
			then to_date(cleaned_date, 'dd.mm.yyyy')
		when length(split_part(cleaned_date, '.', 3)) = 2
			then to_date(cleaned_date, 'dd.mm.yy')
		else null
	end as event_datetime_clean
from cleaned


-- Завдання 1.6
with cleaned_users as (    -- очищення дати реєстрації
	select *, replace(replace(split_part(trim(signup_datetime),' ', 1), '/', '.'), '-', '.') as cleaned_signup
	from project.cohort_users_raw),
cleaned_events as (        -- очищення дати події
	select *, replace(replace(split_part(trim(event_datetime),' ', 1), '/', '.'), '-', '.') as cleaned_event
	from project.cohort_events_raw),
users_with_date as (       -- перетворення очищеного рядка дати реєстрації на тип date
	select *,
	case 
		when length(split_part(cleaned_signup, '.', 3)) = 4
			then to_date(cleaned_signup, 'dd.mm.yyyy')
		when length(split_part(cleaned_signup, '.', 3)) = 2
			then to_date(cleaned_signup, 'dd.mm.yy')
		else null
	end as signup_date_clean
	from cleaned_users),
events_with_date as (      -- перетворення очищеного рядка дати події на тип date
	select *, 
	case 
		when length(split_part(cleaned_event, '.', 3)) = 4
			then to_date(cleaned_event, 'dd.mm.yyyy')
		when length(split_part(cleaned_event, '.', 3)) = 2
			then to_date(cleaned_event, 'dd.mm.yy')
		else null
	end as event_date_clean
	from cleaned_events)
select ud.user_id, date_trunc('month', ud.signup_date_clean)::date as cohort_month, 
	   ed.user_id, date_trunc('month', ed.event_date_clean)::date as event_month,
	   (extract(year from ed.event_date_clean) * 12 + extract(month from ed.event_date_clean)) - 
	   		(extract(year from ud.signup_date_clean) * 12 + extract(month from ud.signup_date_clean)) as month_offset -- скільки місяців пройшло від реєстрації до події
from users_with_date ud
join events_with_date ed
on ud.user_id = ed.user_id
where ud.signup_date_clean is not null 
	  and ed.event_date_clean is not null 
	  and ed.event_type is not null 
	  and ed.event_type <> 'test_event'
limit 50;


-- завдання 1.7
with cleaned_users as (   -- очищення дати реєстрації
	select *, replace(replace(split_part(trim(signup_datetime),' ', 1), '/', '.'), '-', '.') as cleaned_signup
	from project.cohort_users_raw),
cleaned_events as (       -- очищення дати події
	select *, replace(replace(split_part(trim(event_datetime),' ', 1), '/', '.'), '-', '.') as cleaned_event
	from project.cohort_events_raw),
users_with_date as (      -- перетворення очищеного рядка дати реєстрації на тип date
	select *,
	case 
		when length(split_part(cleaned_signup, '.', 3)) = 4
			then to_date(cleaned_signup, 'dd.mm.yyyy')
		when length(split_part(cleaned_signup, '.', 3)) = 2
			then to_date(cleaned_signup, 'dd.mm.yy')
		else null
	end as signup_date_clean
	from cleaned_users),
events_with_date as (    -- перетворення очищеного рядка дати події на тип date
	select *, 
	case 
		when length(split_part(cleaned_event, '.', 3)) = 4
			then to_date(cleaned_event, 'dd.mm.yyyy')
		when length(split_part(cleaned_event, '.', 3)) = 2
			then to_date(cleaned_event, 'dd.mm.yy')
		else null
	end as event_date_clean
	from cleaned_events)
select ud.promo_signup_flag,
	   date_trunc('month', ud.signup_date_clean)::date as cohort_month,
	   (extract(year from ed.event_date_clean) * 12 + extract(month from ed.event_date_clean)) - 
	   		(extract(year from ud.signup_date_clean) * 12 + extract(month from ud.signup_date_clean)) as month_offset,
	   count(distinct ud.user_id) as users_total
from users_with_date ud
join events_with_date ed
on ud.user_id = ed.user_id
where ud.signup_date_clean is not null
	  and ed.event_date_clean is not null 
	  and ed.event_type is not null 
	  and ed.event_type <> 'test_event'
	  and date_trunc('month', ed.event_date_clean) between '2025.01.01' and '2025.06.01' -- тільки події за січень-червень 2025
group by ud.promo_signup_flag, cohort_month, month_offset
order by ud.promo_signup_flag, cohort_month, month_offset;


