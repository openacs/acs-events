-- packages/acs-events/sql/timespan-create.sql
--
-- This script defines the data models and API for both time_interval and timespan.
--
-- @author smeeks@arsdigita.com
-- @creation-date 2000-11-16
--
-- $Id$

create sequence timespan_sequence start  1;
-- create view timespan_seq as select nextval('timespan_sequence') as nextval from dual;

-- Table for storing time intervals.  Note that time intervals can be open on 
-- either end.  This is represented by a null value for start_date or end_date.
-- Applications can determine how to interpret null values.  However, this is 
-- the default interpretation used by the overlaps_p functions. A null value
-- for start_date is treated as extending to the beginning of time.  A null
-- value for end_date is treated as extending to the end of time.  The net effect
-- is that an interval with an open start overlaps any interval whose start
-- is before the end of the interval with the open start.  Likewise, an interval
-- with an open end overlaps any interval whose end is after the start of the
-- interval with the open end.
create table time_intervals (
    interval_id         integer
                        constraint time_intervals_pk
                        primary key,
    start_date          timestamptz,
    end_date            timestamptz,
    constraint time_interval_date_order_ck
    check(start_date <= end_date)
);

create index time_intervals_start_idx on time_intervals(start_date);

comment on table time_intervals is '
    A time interval is represented by two points in time.
';      

-- API:
--
--       new        (start_date, end_date)
--       delete     ()
--
--       edit       (start_date, end_date)
--
--       shift      (start_offset, end_offset)
--
--       overlaps_p (interval_id) 
--       overlaps_p (start_date, end_date)
--




-- added
select define_function_args('time_interval__new','start_date;null,end_date;null');

--
-- procedure time_interval__new/2
--
     -- 
     -- Creates a new time interval
     --
     -- @author W. Scott Meeks
     --
     -- @param start_date   Sets this as start_date of new interval
     -- @param end_date     Sets this as end_date of new interval
     --
     -- @return id of new time interval
     --
CREATE OR REPLACE FUNCTION time_interval__new(
   new__start_date timestamptz,   -- default null
   new__end_date timestamptz      -- default null

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
select define_function_args('time_interval__delete','interval_id');

--
-- procedure time_interval__delete/1
--
     --
     -- Deletes the given time interval
     --
     -- @author W. Scott Meeks
     --
     -- @param interval_id  id of the interval to delete
     --
     -- @return 0 (procedure dummy)
     --
CREATE OR REPLACE FUNCTION time_interval__delete(
   delete__interval_id integer

) RETURNS integer AS $$
DECLARE
BEGIN
       delete from time_intervals
       where  interval_id = delete__interval_id;

       return 0;
END;
$$ LANGUAGE plpgsql; 

 


-- added
select define_function_args('time_interval__edit','interval_id,start_date;null,end_date;null');

--
-- procedure time_interval__edit/3
--
     -- 
     -- Updates the start_date or end_date of an interval
     --
     -- @author W. Scott Meeks
     --
     -- @param interval_id  id of the interval to update
     -- @param start_date   Sets this as the new 
     --                     start_date of the interval.
     -- @param end_date     Sets this as the new 
     --                     end_date of the interval.
     --
     -- @return 0 (procedure dummy)
     --

CREATE OR REPLACE FUNCTION time_interval__edit(
   edit__interval_id integer,
   edit__start_date timestamptz, -- default null
   edit__end_date timestamptz    -- default null

) RETURNS integer AS $$
DECLARE
BEGIN

        -- JS: I hate deeply nested if-else-ifs!!! 

        -- Null for start_date or end_date means dont change.
        if edit__start_date is not null and edit__end_date is not null then
            update time_intervals
            set    start_date  = edit__start_date,
                   end_date    = edit__end_date
            where  interval_id = edit__interval_id;
        end if;

        -- Update only the end date if not null even if start date is null
        if edit__start_date is not null and edit__end_date is null 
        then
            update time_intervals
            set    start_date  = edit__start_date
            where  interval_id = edit__interval_id;
        end if;
            
        -- Update only the start date if not null even if end date is null
        if edit__end_date is not null and edit__start_date is null 
        then
                 update time_intervals
                 set end_date       = edit__end_date
                 where interval_id  = edit__interval_id;
        end if;

        return 0;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('time_interval__shift','interval_id,start_offset;0,end_offset;0');

--
-- procedure time_interval__shift/3
--
     --
     -- Updates the start_date or end_date of an interval based on offsets (general)
     --
     -- @author W. Scott Meeks
     -- @param interval_id  The interval to update.
     -- @param start_offset Adds this date interval to the
     --                     start_date of the interval.  No effect if 
     --                     start_date is null.
     -- @param end_offset   Adds this date interval to the
     --                     end_date of the interval.  No effect if 
     --                     end_date is null.
     --
     -- @return 0 (procedure dummy)
     --
CREATE OR REPLACE FUNCTION time_interval__shift(
   shift__interval_id integer,
   shift__start_offset interval, -- default 0,
   shift__end_offset interval    -- default 0

) RETURNS integer AS $$
DECLARE 
BEGIN
       update time_intervals
       set    start_date = start_date + shift__start_offset,
              end_date   = end_date + shift__end_offset
       where  interval_id = shift__interval_id;

       return 0;

END;
$$ LANGUAGE plpgsql; 




--
-- procedure time_interval__shift/3
--
    --
    -- Updates the start_date or end_date of an interval based on offsets of
    -- fractional days.
    --
    -- JS: Overloaded function to make above compatible with Oracle behavior
    -- JS: when an integer (for number of days) is supplied as a parameter.
    --
    -- @param interval_id  The interval to update.
    -- @param start_offset Adds this number of days to the
    --                     start_date of the interval.  No effect if 
    --                     start_date is null.
    -- @param end_offset   Adds this number of days to the
    --                     end_date of the interval.  No effect if 
    --                     end_date is null.
    --
    -- @return 0 (procedure dummy)
CREATE OR REPLACE FUNCTION time_interval__shift(
   shift__interval_id integer,
   shift__start_offset integer, -- default 0,
   shift__end_offset integer    -- default 0

) RETURNS integer AS $$
DECLARE 
BEGIN

      return time_interval__shift(
                 shift__interval_id,
                 to_interval(shift__start_offset,'days'),
                 to_interval(shift__end_offset,'days')
                 );

END;
$$ LANGUAGE plpgsql;




-- added

--
-- procedure time_interval__overlaps_p/2
--
    -- 
    -- Returns true if the two intervals overlap, false otherwise.
    --
    -- @author W. Scott Meeks
    --
    -- @param interval_1_id
    -- @param interval_2_id
    --
    -- @return true if the two intervals overlap, false otherwise.
    --
CREATE OR REPLACE FUNCTION time_interval__overlaps_p(
   overlaps_p__interval_id_1 integer,
   overlaps_p__interval_id_2 integer

) RETURNS boolean AS $$
DECLARE
       v_start_1                   timestamptz;
       v_start_2                   timestamptz;
       v_end_1                     timestamptz;
       v_end_2                     timestamptz;
BEGIN
       -- Pull out the start and end dates and call the main overlaps_p.
       select start_date, end_date
       into   v_start_1, v_end_1
       from   time_intervals
       where  interval_id = overlaps_p__interval_id_1;

       select start_date, end_date
       into   v_start_2, v_end_2
       from   time_intervals
       where  interval_id = overlaps_p__interval_id_2;

       return time_interval__overlaps_p(
                  v_start_1, 
                  v_end_1, 
                  v_start_2, 
                  v_end_2
                  );

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('time_interval__overlaps_p','interval_id,start_date;null,end_date;null');

--
-- procedure time_interval__overlaps_p/3
--
    --
    -- Returns true if the interval bounded by the given start_date or
    -- end_date overlaps the given interval, false otherwise.
    --
    -- @author W. Scott Meeks
    --
    -- @param start_date  See if it overlaps the interval starting from this date.
    -- @param end_date    See if it overlaps the interval ending on this date.
    --
    -- @return true if the interval bounded by start_date through end_date, false otherwise.
    --
CREATE OR REPLACE FUNCTION time_interval__overlaps_p(
   overlaps_p__interval_id integer,
   overlaps_p__start_date timestamptz, -- default null,
   overlaps_p__end_date timestamptz    -- default null

) RETURNS boolean AS $$
DECLARE
       v_interval_start            time_intervals.start_date%TYPE;
       v_interval_end              time_intervals.end_date%TYPE;
BEGIN
       -- Pull out the start and end date and call the main overlaps_p.
       select start_date, end_date
       into   v_interval_start, v_interval_end
       from   time_intervals
       where  interval_id = overlaps_p__interval_id;

       return time_interval__overlaps_p(
                  v_interval_start, 
                  v_interval_end, 
                  overlaps_p__start_date, 
                  overlaps_p__end_date
                  );

END;
$$ LANGUAGE plpgsql; 




--
-- procedure time_interval__overlaps_p/4
--
    --
    -- Checks if two intervals overlaps
    -- JS:  There is a simpler way to evaluate whether intervals overlap, 
    -- JS:  so this function can be optimized.
    --
    -- @author W. Scott Meeks
    --
    -- @param interval_1_id First interval
    -- @param interval_2_id Second interval
    -- 
    -- @return true if intervals overlap, otherwise false.
    --
CREATE OR REPLACE FUNCTION time_interval__overlaps_p(
   overlaps_p__start_1 timestamptz,
   overlaps_p__end_1 timestamptz,
   overlaps_p__start_2 timestamptz,
   overlaps_p__end_2 timestamptz

) RETURNS boolean AS $$
DECLARE
BEGIN

       -- JS: Modified yet another deeply nested if-else-if
       -- JS: Note that null date is the representation for infinite 
       -- (positive or negative) time. 
       if overlaps_p__start_1 is null 
       then
            -- No overlap if 2nd interval starts after 1st ends
            if overlaps_p__end_1 < overlaps_p__start_2 
            then
                return false;
            else
                return true;
            end if;
       end if;

       if overlaps_p__start_2 is null 
       then
            -- No overlap if 2nd interval ends before 1st starts
            if overlaps_p__end_2 < overlaps_p__start_1 
            then
                return false;
            else
                return true;
            end if;
       end if;

       -- Okay, both start dates are not null
       if overlaps_p__start_1 <= overlaps_p__start_2 
       then
            -- 1st starts before 2nd
            if overlaps_p__end_1 < overlaps_p__start_2 
            then
                  -- No overlap if 1st ends before 2nd starts
                  return false;
            else
                 -- No overlap or at least one null
                 return true;
            end if;

       else

            -- 1st starts after 2nd
            if overlaps_p__end_2 < overlaps_p__start_1 
            then
                 -- No overlap if 2nd ends before 1st starts
                 return false;
            else
                 -- No overlap or at least one null
                 return true;
            end if;

       end if;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('time_interval__eq','interval_1_id,interval_2_id');

--
-- procedure time_interval__eq/2
--
    --
    -- Checks if two intervals are equal
    --
    -- @author W. Scott Meeks
    --
    -- @param interval_1_id First interval
    -- @param interval_2_id Second interval
    -- 
    -- @return true if intervals are equal, otherwise false.
    --
CREATE OR REPLACE FUNCTION time_interval__eq(
   eq__interval_1_id integer,
   eq__interval_2_id integer

) RETURNS boolean AS $$
--  return boolean
DECLARE
       interval_1_row time_intervals%ROWTYPE;
       interval_2_row time_intervals%ROWTYPE;
BEGIN
       select * into interval_1_row
       from   time_intervals
       where  interval_id = eq__interval_1_id;

       select * into interval_2_row
       from   time_intervals
       where  interval_id = eq__interval_2_id;

       if interval_1_row.start_date = interval_2_row.start_date and 
          interval_1_row.end_date = interval_2_row.end_date 
       then
            return true;
       else
            return false;
       end if;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('time_interval__copy','interval_id,offset;0');

--
-- procedure time_interval__copy/2
--
    --
    -- Creates a new copy of a time interval, offset by optional offset
    --
    -- JS: We need to be careful in interpreting the copy offset.
    -- JS: Oracle interprets integers as full days when doing
    -- JS: date arithmetic.  Thus,
    -- JS: 
    -- JS:    select sysdate()+1 from dual;
    -- JS:
    -- JS: will yield the next date, correct up to the second of the next day
    -- JS: that the query was run.  
    -- JS: 
    -- JS: In PostgreSQL, we need to specify the type of interval when
    -- JS: doing date arithmetic.  if, say, an integer is used in date arithmetic, 
    -- JS: the results are weird.  For example, 
    -- JS:
    -- JS:    select now()+1 from dual;
    -- JS:
    -- JS: will yield the MIDNIGHT of the next date that the query was run, i.e.,
    -- JS: the timestamp is typecasted as a date with a day granularity. To get the 
    -- JS: same effect as Oracle, we need to use explicitly typecast the integer into 
    -- JS: a day interval. 
    --
    -- @author W. Scott Meeks
    --
    -- @param interval_id   Interval to copy
    -- @param offset        Interval is offset by this date interval
    --
    -- @return interval_id of the copied interval
CREATE OR REPLACE FUNCTION time_interval__copy(
   copy__interval_id integer,
   copy__offset interval -- default 0

) RETURNS integer AS $$
DECLARE    
       interval_row           time_intervals%ROWTYPE;
       v_foo                 timestamptz;
BEGIN
       select * into interval_row
       from   time_intervals
       where  interval_id = copy__interval_id;
	
       return time_interval__new(
                  (interval_row.start_date ::timestamp + copy__offset) :: timestamptz,
                  (interval_row.end_date ::timestamp + copy__offset) :: timestamptz
                  );

END;
$$ LANGUAGE plpgsql; 



--
-- procedure time_interval__copy/1
--
    --
    -- Creates a new copy of a time interval.
    -- JS: Overloaded versaion of above, no offset
    --
    -- @param interval_id   Interval to copy
    --
    -- @return interval_id of the copied interval
    --
CREATE OR REPLACE FUNCTION time_interval__copy(
   copy__interval_id integer

) RETURNS integer AS $$
-- return time_intervals.interval_id%TYPE
DECLARE    
       v_query               varchar;
       v_result              time_intervals.interval_id%TYPE;
       rec_datecalc          record;
BEGIN
        return time_interval__copy(
                   copy__interval_id,
                   interval '0 days'
                   );

END;
$$ LANGUAGE plpgsql;




--
-- procedure time_interval__copy/2
--
    --
    -- Creates a new copy of a time interval, offset by optional offset
    --
    -- JS: Overloaded function to make above compatible with Oracle behavior
    -- JS: when an integer (for number of days) is supplied as a parameter.
    --
    -- @param interval_id   Interval to copy
    -- @param offset        Interval is offset by this number of days
    --
    -- @return interval_id of the copied interval
    --
CREATE OR REPLACE FUNCTION time_interval__copy(
   copy__interval_id integer,
   copy__offset integer -- default 0

) RETURNS integer AS $$
DECLARE    
BEGIN

       return time_interval__copy(
                  copy__interval_id,
                  to_interval(copy__offset,'days')
                  );

END;
$$ LANGUAGE plpgsql;







-- Timespans table. A timespan is a set of intervals.  This table contains
-- mappings of intervals into a set that comprises a timespan.
create table timespans (           
    -- Can't be primary key because of the one to many relationship with
    -- interval_id, but we can declare it not null and index it.
    timespan_id     integer not null,
    interval_id     integer
                    constraint tm_ntrvl_sts_interval_id_fk
                    references time_intervals on delete cascade
);

create index timespans_idx on timespans(timespan_id);

-- This is important to prevent locking on update of master table.
-- See  http://www.arsdigita.com/bboard/q-and-a-fetch-msg.tcl?msg_id=000KOh
-- JS: Not sure if this applies to PostgreSQL, but an index cant hurt, can it?
create index timespans_interval_id_idx on timespans(interval_id);

comment on table timespans is '
    Establishes a relationship between timespan_id and multiple time
    intervals.  Represents a range of moments at which an event can occur.
';


-- TimeSpan API
--
-- Quick reference for the API supported for timespans.  All procedures take timespan_id
-- as the first argument (not shown explicitly):
-- 
--     new          (interval_id)
--     new          (start_date, end_date)
--     delete       ()
--
-- Methods to join additional time intervals with an existing timespan:
--
--     join          (timespan_id)
--     join_interval (interval_id)
--     join          (start_date, end_date)
--
--     interval_delete (interval_id)
--     interval_list   ()
--
-- Tests for overlap:
-- 
--     overlaps_p   (timespan_id)
--     overlaps_p   (interval_id)
--     overlaps_p   (start_date, end_date)
--
-- Info:
--
--         exists_p                     ()
--     multi_interval_p ()




-- added

--
-- procedure timespan__new/2
--
    --
    -- Creates a new timespan (20.20.10)
    -- given a time_interval
    --
    -- JS: Allow user to specify whether the itme interval is to be copied or not
    -- JS: This gives more flexibility of not making a copy instead of requiring 
    -- JS: the caller responsible for deleting the copy.
    --
    -- @author W. Scott Meeks
    --
    -- @param interval_id    Id of interval to be included/copied in timespan, 
    -- @param copy_p         If true, make another copy of the interval, 
    --                       else simply include the interval in the timespan
    --
    -- @return Id of new timespan       
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
--  end new;



--
-- procedure timespan__new/1
--
    --
    -- Creates a new timespan (20.20.10)
    -- given a time_interval
    --
    -- JS: I understand why we want to copy here (since interval_id
    -- JS: may be used by another), but see note on time_span__copy
    -- JS: below.   THE ONLY REASON WHY DEFAULT IS TRUE IS TO MAINTAIN
    -- JS: COMPATIBILITY WITH ORIGINAL VERSION.  I DO NOT THINK TRUE
    -- JS: SHOULD BE THE DEFAULT.
    --
    -- @param interval_id    Id of interval to be copied in timespan, 
    --
    -- @return Id of new timespan       
    --
CREATE OR REPLACE FUNCTION timespan__new(
   new__interval_id integer

) RETURNS integer AS $$
DECLARE
BEGIN
        return timespan__new(
                   new__interval_id,
                   true
                   );
        
END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__new','start_date;null,end_date;null');

--
-- procedure timespan__new/2
--
    --
    -- Creates a new timespan (20.20.10)
    -- given a start date and end date.  A new time interval with the 
    -- start and end dates is automatically created.
    --
    -- @param start_date     Start date of interval to be included/copied in timespan, 
    -- @param end_date       End date of interval to be included/copied in timespan, 
    --
    -- @return Id of new timespan       
    --
CREATE OR REPLACE FUNCTION timespan__new(
   new__start_date  timestamptz,     -- default null,
   new__end_date timestamptz         -- default null

) RETURNS integer AS $$
DECLARE
BEGIN

       -- JS: If we simply call timespan__new with default copy_p = true,
       -- JS: there will be two new time intervals that will be created
       -- JS: everytime this function is called. The first one will never be used!!! 
       -- JS: To fix, we use the timespan__new with copy_p parameter and
       -- JS: setting copy_p to false.
       return timespan__new(time_interval__new(new__start_date, new__end_date),false);

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__delete','timespan_id');

--
-- procedure timespan__delete/1
--
    -- 
    -- Deletes the timespan and any contained intervals 
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   Id of timespan to delete
    --
    -- @return 0 (procedure dummy)
    --
CREATE OR REPLACE FUNCTION timespan__delete(
   delete__timespan_id integer

) RETURNS integer AS $$
DECLARE
BEGIN
       -- Delete intervals, corresponding timespan entries deleted by
       -- cascading constraints

       delete from time_intervals
       where  interval_id in (select interval_id
                              from   timespans
                              where  timespan_id = delete__timespan_id);
       return 0;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__join_interval','timespan_id,interval_id,copy_p;true');

--
-- procedure timespan__join_interval/3
--
    --
    -- Join a time interval to an existing timespan
    --
    -- JS: Slight changes from original
    -- JS: Return the interval_id being joined, since it will not be the
    -- JS: same as join_interval__interval_id if join_interval__copy_p is true
    -- JS: The Oracle version is a procedure, so this change is completely free.
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   Id of timespan to join to
    -- @param interval_id   Id of interval to include/copy into timespan
    -- @param copy_p        If true, make a new copy of he interval for inclusion
    --                      into the timespan, otherwise simply include the interval
    --
    -- @return Id of interval being joined
    --
CREATE OR REPLACE FUNCTION timespan__join_interval(
   join_interval__timespan_id integer,
   join_interval__interval_id integer,
   join_interval__copy_p boolean -- default true

) RETURNS integer AS $$
-- time_intervals.interval_id%TYPE
DECLARE
       v_interval_id                  time_intervals.interval_id%TYPE;
BEGIN
       if join_interval__copy_p then
           v_interval_id := time_interval__copy(join_interval__interval_id);
       else
           v_interval_id := join_interval__interval_id;
       end if;
        
       insert into timespans
            (timespan_id, interval_id)
       values
            (join_interval__timespan_id, v_interval_id);

       -- JS: We might as well return the interval id being joined, instead of returning a dummy integer
       return v_interval_id;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__join','timespan_id,start_date;null,end_date;null');

--
-- procedure timespan__join/3
--
    --
    -- Join a new interval with start and end dates to an existing timespan
    --
    -- JS: Slight change from original
    -- JS: Return the interval_id being joined (Oracle version is a procedure)
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   Id of timespan to join new interval
    -- @param start_date    Start date of new interval to join to timespan
    -- @param end_date      End date of new interval to join to timespan
    --
    -- @return Id of interval being joined
    --
CREATE OR REPLACE FUNCTION timespan__join(
   join__timespan_id integer,
   join__start_date timestamptz, -- default null,
   join__end_date timestamptz    -- default null

) RETURNS integer AS $$
DECLARE
BEGIN

       -- JS: This will create a new interval with start_date and end_date
       -- JS: so we might as well return the interval id 
       return timespan__join_interval(
                join__timespan_id, 
                time_interval__new(join__start_date, join__end_date),
                false
                );

END;
$$ LANGUAGE plpgsql; 




--
-- procedure timespan__join/2
--
    --
    -- Join a new timespan or time interval to an existing timespan
    --
    -- JS: Slight changes from original
    -- JS: Return the last interval_id being joined. Although probably not useful
    -- JS: we return the interval_id anyways to make the function consisted with
    -- JS: the rest.  Oracle version is a procedure.
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   Id of timespan to join to
    -- @param timespan_id   Id of timespan to join from
    --
    -- @return Id of last interval in timespan being joined
    --
CREATE OR REPLACE FUNCTION timespan__join(
   join__timespan_1_id integer,
   join__timespan_2_id integer

) RETURNS integer AS $$
DECLARE
       v_interval_id          time_intervals.interval_id%TYPE;
       rec_timespan           record;
BEGIN
       -- Loop over intervals in 2nd timespan, join with 1st.
       for rec_timespan in 
            select * 
            from   timespans
            where  timespan_id = join__timespan_2_id
       loop
            v_interval_id := timespan__join_interval(
                                  join__timespan_1_id, 
                                  rec_timespan.interval_id,
                                  false
                                  );
       end loop;

       -- JS: Return the last interval id joined.  Not very useful, since there may be
       -- JS: more than one interval joined
       return v_interval_id;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__interval_delete','timespan_id,interval_id');

--
-- procedure timespan__interval_delete/2
--
    --
    -- Deletes an interval from the given timespan
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   timespan to delete from
    -- @param interval_id   delete this interval from the set
    --
    -- @return 0 (procedure dummy)
    --
CREATE OR REPLACE FUNCTION timespan__interval_delete(
   interval_delete__timespan_id integer,
   interval_delete__interval_id integer

) RETURNS integer AS $$
DECLARE
BEGIN

       delete from timespans
       where timespan_id = interval_delete__timespan_id
       and   interval_id = interval_delete__interval_id;

       return 0;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__exists_p','timespan_id');

--
-- procedure timespan__exists_p/1
--
    --
    -- If its contained intervals are all deleted, then a timespan will
    -- automatically be deleted.  This checks a timespan_id to make sure it is
    -- still valid.
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   id of timespan to check
    --
    -- @return true if interval is in timespan set, otherwise false.
    --
CREATE OR REPLACE FUNCTION timespan__exists_p(
   exists_p__timespan_id integer

) RETURNS boolean AS $$
DECLARE
       v_result         integer;
BEGIN
       -- Only need to check if any rows exist. 
       select count(*)
       into   v_result
       from dual
       where exists (select timespan_id
                     from   timespans
                     where  timespan_id = exists_p__timespan_id);

       if v_result = 0 then
           return false;
       else
           return true;
       end if;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__multi_interval_p','timespan_id');

--
-- procedure timespan__multi_interval_p/1
--
    --
    -- Checks if timespan contains more than one interval
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   id of timespan to check
    --
    -- @return true if timespan has more than one interval, otherwise false.
    --
CREATE OR REPLACE FUNCTION timespan__multi_interval_p(
   multi_interval_p__timespan_id integer

) RETURNS boolean AS $$
DECLARE
       v_result                 boolean;
BEGIN
       -- 'f' if 0 or 1 intervals, 't' otherwise
       -- use the simple case syntax
       select (case count(timespan_id) 
                    when 0 then false
                    when 1 then false 
                    else true
               end)
       into v_result
       from timespans
       where timespan_id = multi_interval_p__timespan_id;
        
       return v_result;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__overlaps_interval_p','timespan_id,interval_id;null');

--
-- procedure timespan__overlaps_interval_p/2
--
    --
    -- Checks to see interval overlaps any of the intervals in the timespan. 
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   id of timespan as reference
    -- @param timespan_id   id of timespan to check 
    --
    -- @return true if interval overlaps with anyinterval in timespan, otherwise false.
    --
CREATE OR REPLACE FUNCTION timespan__overlaps_interval_p(
   overlaps_interval_p__timespan_id integer,
   overlaps_interval_p__interval_id integer -- default null

) RETURNS boolean AS $$
DECLARE
       v_start_date               timestamptz;
       v_end_date                 timestamptz;
BEGIN
       select start_date, end_date
       into   v_start_date, v_end_date
       from   time_intervals
       where  interval_id = overlaps_interval_p__interval_id;
        
       return timespan__overlaps_p(
                        overlaps_interval_p__timespan_id, 
                        v_start_date, 
                        v_end_date
                        );

END;
$$ LANGUAGE plpgsql; 




-- added

--
-- procedure timespan__overlaps_p/2
--
    --
    -- Checks to see if any intervals in a timespan overlap any of the intervals
    -- in the second timespan. 
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   id of timespan as reference
    -- @param timespan_id   id of timespan to check 
    --
CREATE OR REPLACE FUNCTION timespan__overlaps_p(
   overlaps_p__timespan_1_id integer,
   overlaps_p__timespan_2_id integer

) RETURNS boolean AS $$
DECLARE
       v_result             boolean;
       rec_timespan                 record;
BEGIN
       -- Loop over 2nd timespan, checking each interval against 1st
       for rec_timespan in 
            select * 
            from timespans
            where timespan_id = overlaps_p__timespan_2_id
       loop
            v_result := timespan__overlaps_interval_p(
                                overlaps_p__timespan_1_id,
                                rec_timespan.interval_id
                                );
            if v_result then
                return true;
            end if;
       end loop;

       return false;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__overlaps_p','timespan_id,start_date;null,end_date;null');

--
-- procedure timespan__overlaps_p/3
--
    --
    -- Checks to see if interval with start and end dates overlap any of the intervals
    -- in the timespan. 
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   Id of timespan as reference
    -- @param start_date    Start date of interval
    -- @param end_date    End date of interval
    --
    -- @return true if interval with start and end dates overlaps with second timespan, otherwise false.
    --
CREATE OR REPLACE FUNCTION timespan__overlaps_p(
   overlaps_p__timespan_id integer,
   overlaps_p__start_date timestamptz, -- default null,
   overlaps_p__end_date timestamptz    -- default null

) RETURNS boolean AS $$
DECLARE
       v_result                    boolean;
       rec_timespan                record;
BEGIN
       -- Loop over each interval in timespan, checking against dates.
       for rec_timespan in
            select * 
            from timespans
            where timespan_id = overlaps_p__timespan_id
       loop
            v_result := time_interval__overlaps_p(
                                rec_timespan.interval_id, 
                                overlaps_p__start_date,
                                overlaps_p__end_date
                                );

            if v_result then
                return true;
            end if;
       end loop;

       return false;

END;
$$ LANGUAGE plpgsql; 




-- added
select define_function_args('timespan__copy','timespan_id,offset');

--
-- procedure timespan__copy/2
--
    --
    -- Creates a new copy of a timespan, offset by optional offset
    -- JS:  See note on intervals on time_interval__copy
    --
    -- @author W. Scott Meeks
    --
    -- @param timespan_id   Timespan to copy
    -- @param offset        Offset al dates in timespan by this date interval
    --
    -- @return Id of copied timespan
    --
CREATE OR REPLACE FUNCTION timespan__copy(
   copy__timespan_id integer,
   copy__offset interval --  default 0

) RETURNS integer AS $$
DECLARE
       rec_timespan             record;
       v_interval_id            timespans.interval_id%TYPE;
       v_timespan_id            timespans.timespan_id%TYPE;
BEGIN
       v_timespan_id := null;

       -- Loop over each interval in timespan, creating a new copy
       for rec_timespan in 
            select * 
            from timespans
            where timespan_id = copy__timespan_id
       loop
            v_interval_id := time_interval__copy(
                                rec_timespan.interval_id, 
                                copy__offset
                                );

            if v_timespan_id is null 
            then
                 -- JS: NOTE DEFAULT BEHAVIOR OF timespan__new
                v_timespan_id := timespan__new(v_interval_id);
            else
                -- no copy, use whatever is generated by time_interval__copy
                PERFORM timespan__join_interval(
                                v_timespan_id, 
                                v_interval_id,
                                false);
            end if;

       end loop;

       return v_timespan_id;

END;
$$ LANGUAGE plpgsql; 




--
-- procedure timespan__copy/1
--
    --
    -- Creates a new copy of a timespan, no offset
    --
    -- @param timespan_id   Timespan to copy
    -- @param offset        Offset al dates in timespan by this date interval
    --
    -- @return Id of copied timespan
    --
CREATE OR REPLACE FUNCTION timespan__copy(
   copy__timespan_id integer

) RETURNS integer AS $$
-- timespans.timespan_id%TYPE
DECLARE
BEGIN

       return timespan__copy(
                    copy__timespan_id,
                    interval '0 days'
                    );

END;
$$ LANGUAGE plpgsql; 
        



--
-- procedure timespan__copy/2
--
    --
    -- Creates a new copy of a timespan, offset by optional offset
    -- JS: Overloaded function to make above compatible with Oracle behavior
    -- JS: when an integer (for number of days) is supplied as a parameter.
    --
    -- @param timespan_id   Timespan to copy
    -- @param offset        Offset all dates in timespan by this number of days
    --
    -- @return Id of copied timespan
    --
CREATE OR REPLACE FUNCTION timespan__copy(
   copy__timespan_id integer,
   copy__offset integer

) RETURNS integer AS $$
DECLARE
BEGIN
       return timespan__copy(
                    copy__timespan_id,
                    to_interval(copy__offset,'days')
                    );

END;
$$ LANGUAGE plpgsql; 
