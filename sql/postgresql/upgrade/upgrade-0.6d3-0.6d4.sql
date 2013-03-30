-- 
-- 
-- 
-- @author Victor Guerra (vguerra@gmail.com)
-- @creation-date 2010-11-05
-- @cvs-id $Id$
--

-- PG 9.x support - changes regarding usage of sequences

drop view acs_events_seq;
drop sequence acs_events_sequence;
drop view timespan_seq;
drop view recurrence_seq;



-- added
select define_function_args('time_interval__new','start_date;null,end_date;null');

--
-- procedure time_interval__new/2
--
CREATE OR REPLACE FUNCTION time_interval__new(
   new__start_date timestamptz,  -- default null,
   new__end_date timestamptz     -- default null

) RETURNS integer AS $$
DECLARE
       v_interval_id     time_intervals.interval_id%TYPE;
BEGIN
       select nextval('timespan_sequence') into v_interval_id from dual;

       insert into time_intervals 
            (interval_id, start_date, end_date)
       values
            (v_interval_id, new__start_date, new__end_date);
                
       return v_interval_id;

END;
$$ LANGUAGE plpgsql; 



-- added

--
-- procedure timespan__new/2
--
CREATE OR REPLACE FUNCTION timespan__new(
   new__interval_id integer,
   new__copy_p boolean

) RETURNS integer AS $$
-- timespans.timespan_id%TYPE
DECLARE
        v_timespan_id           timespans.timespan_id%TYPE;
        v_interval_id           time_intervals.interval_id%TYPE;
BEGIN
        -- get a new id;
        select nextval('timespan_sequence') into v_timespan_id from dual;

        if new__copy_p
        then      
             -- JS: Note use of overloaded function (zero offset)
             v_interval_id := time_interval__copy(new__interval_id);
        else
             v_interval_id := new__interval_id;
        end if;
        
        insert into timespans
            (timespan_id, interval_id)
        values
            (v_timespan_id, v_interval_id);
        
        return v_timespan_id;

END;
$$ LANGUAGE plpgsql; 



-- added
select define_function_args('recurrence__new','interval_name,every_nth_interval,days_of_week;null,recur_until;null,custom_func;null');

--
-- procedure recurrence__new/5
--
CREATE OR REPLACE FUNCTION recurrence__new(
   new__interval_name varchar,
   new__every_nth_interval integer,
   new__days_of_week varchar,    -- default null,
   new__recur_until timestamptz, -- default null,
   new__custom_func varchar      -- default null

) RETURNS integer AS $$
	-- recurrences.recurrence_id%TYPE
DECLARE
       v_recurrence_id		  recurrences.recurrence_id%TYPE;
       v_interval_type_id	  recurrence_interval_types.interval_type%TYPE;
BEGIN

       select nextval('recurrence_sequence') into v_recurrence_id from dual;
        
       select interval_type
       into   v_interval_type_id 
       from   recurrence_interval_types
       where  interval_name = new__interval_name;
        
       insert into recurrences
            (recurrence_id, 
             interval_type, 
             every_nth_interval, 
             days_of_week,
             recur_until, 
             custom_func)
       values
            (v_recurrence_id, 
             v_interval_type_id, 
             new__every_nth_interval, 
             new__days_of_week,
             new__recur_until, 
             new__custom_func);
         
       return v_recurrence_id;

END;
$$ LANGUAGE plpgsql; 
