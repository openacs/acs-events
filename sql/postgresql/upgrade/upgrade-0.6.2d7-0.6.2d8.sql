---
--- Fix SQL function that were defined with the same number of
--- arguments and the same argument names, but receiving different
--- types (integers vs. timespans). This is fine, as long the
--- functions are only called from SQL and positional arguments. When
--- calling from Tcl, this does not work.
---
--- This change uses in cases, where offsets are specified as
--- intervals the suffix "_interval" for the variable names, keeping
--- the names without this suffix for integer arguments (for Oracle
--- compatibility).
---


DROP FUNCTION acs_event__shift(integer,interval,interval);

CREATE OR REPLACE FUNCTION acs_event__shift(
   shift__event_id integer,      -- default null
   shift__start_offset_interval interval, -- default 0
   shift__end_offset_interval interval    -- default 0

) RETURNS integer AS $$
DECLARE
       rec_events           record;
BEGIN

--       update acs_events_dates
--       set    start_date = start_date + shift__start_offset_interval,
--             end_date   = end_date + shift__end_offset_interval
--       where  event_id   = shift__event_id;

          -- Can not update view, so we do it the hard way
          -- (as if we make the rule anyways)
          for rec_events in
              select t.*
              from acs_events e, timespans s, time_intervals t
              where e.event_id   = shift__event_id
              and   e.timespan_id = s.timespan_id
              and   s.interval_id = t.interval_id
          loop
               update time_intervals
               set    start_date = start_date + shift__start_offset_interval,
                      end_date   = end_date + shift__end_offset_interval
               where  interval_id = rec_events.interval_id;
          end loop;

       return 0;

END;
$$ LANGUAGE plpgsql;



DROP FUNCTION acs_event__shift_all(integer,interval,interval);

CREATE OR REPLACE FUNCTION acs_event__shift_all(
   shift_all__event_id integer,      -- default null
   shift_all__start_offset_inverval interval, -- default 0
   shift_all__end_offset_inverval interval    -- default 0

) RETURNS integer AS $$
DECLARE
        rec_events                 record;
BEGIN


--        update acs_events_dates
--        set    start_date    = start_date + shift_all__start_offset_inverval,
--              end_date      = end_date + shift_all__end_offset_inverval
--        where recurrence_id  = (select recurrence_id
--                                from   acs_events
--                                where  event_id = shift_all__event_id);

        -- Can not update views
        for rec_events in
            select *
            from acs_events_dates
            where recurrence_id  = (select recurrence_id
                                    from   acs_events
                                    where  event_id = shift_all__event_id)
        loop

            PERFORM acs_event__shift(
                        rec_events.event_id,
                        shift_all__start_offset_inverval,
                        shift_all__end_offset_inverval
                        );
        end loop;

        return 0;

END;
$$ LANGUAGE plpgsql;



DROP FUNCTION time_interval__shift(integer,interval,interval);

CREATE OR REPLACE FUNCTION time_interval__shift(
   shift__interval_id integer,
   shift__start_offset_intverval interval, -- default 0,
   shift__end_offset_intverval interval    -- default 0

) RETURNS integer AS $$
DECLARE
BEGIN
       update time_intervals
       set    start_date = start_date + shift__start_offset_intverval,
              end_date   = end_date + shift__end_offset_intverval
       where  interval_id = shift__interval_id;

       return 0;

END;
$$ LANGUAGE plpgsql;


DROP FUNCTION time_interval__copy(integer,interval);

CREATE OR REPLACE FUNCTION time_interval__copy(
   copy__interval_id integer,
   copy__offset_interval interval -- default 0

) RETURNS integer AS $$
DECLARE
       interval_row           time_intervals%ROWTYPE;
       v_foo                 timestamptz;
BEGIN
       select * into interval_row
       from   time_intervals
       where  interval_id = copy__interval_id;

       return time_interval__new(
                  (interval_row.start_date ::timestamp + copy__offset_interval) :: timestamptz,
                  (interval_row.end_date ::timestamp + copy__offset_interval) :: timestamptz
                  );

END;
$$ LANGUAGE plpgsql;


DROP FUNCTION timespan__copy(integer,interval);

CREATE OR REPLACE FUNCTION timespan__copy(
   copy__timespan_id integer,
   copy__offset_interval interval --  default 0

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
                                copy__offset_interval
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
