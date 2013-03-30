


-- added
select define_function_args('acs_event__insert_instances','event_id,cutoff_date;null');

--
-- procedure acs_event__insert_instances/2
--
CREATE OR REPLACE FUNCTION acs_event__insert_instances(
   insert_instances__event_id integer,
   insert_instances__cutoff_date timestamptz -- default null

) RETURNS integer AS $$
DECLARE
       event_row		       acs_events%ROWTYPE;
       recurrence_row		       recurrences%ROWTYPE;
       v_event_id		       acs_events.event_id%TYPE;
       v_interval_name		       recurrence_interval_types.interval_name%TYPE;
       v_n_intervals		       recurrences.every_nth_interval%TYPE;
       v_days_of_week		       recurrences.days_of_week%TYPE;
       v_last_date_done		       timestamptz;
       v_stop_date		       timestamptz;
       v_start_date		       timestamptz;
       v_event_date		       timestamptz;
       v_diff			       integer;
       v_current_date		       timestamptz;
       v_last_day		       timestamptz;
       v_week_date		       timestamptz;
       v_instance_count		       integer;
       v_days_length		       integer;
       v_days_index		       integer;
       v_day_num		       integer;
       rec_execute		       record;
       v_new_current_date              timestamptz;
       v_offset_notice interval;
BEGIN

	-- Get event parameters
        select * into event_row
        from   acs_events
        where  event_id = insert_instances__event_id;

	-- Get recurrence information
        select * into recurrence_row
        from   recurrences
        where  recurrence_id = event_row.recurrence_id;
        

        -- Set cutoff date to stop populating the DB with recurrences
        -- EventFutureLimit is in years. (a parameter of the service)
        if insert_instances__cutoff_date is null then
           v_stop_date := add_months(now(), 12 * to_number(acs_event__get_value('EventFutureLimit'),'99999')::INT);
        else
           v_stop_date := insert_instances__cutoff_date;
        end if;
        
        -- Events only populated until max(cutoff_date, recur_until)
        -- If recur_until null, then defaults to cutoff_date
        if recurrence_row.recur_until < v_stop_date then
           v_stop_date := recurrence_row.recur_until;
        end if;
        
        -- Figure out the date to start from.
	-- JS: I do not understand why the date must be truncated to the midnight of the event date
        select min(start_date)
        into   v_event_date
        from   acs_events_dates
        where  event_id = insert_instances__event_id;

        if recurrence_row.db_populated_until is null then
           v_start_date := v_event_date;
        else
           v_start_date := recurrence_row.db_populated_until;
        end if;
        
        v_current_date   := v_start_date;
        v_last_date_done := v_start_date;
        v_n_intervals    := recurrence_row.every_nth_interval;
        
        -- Case off of the interval_name to make code easier to read
        select interval_name into v_interval_name
        from   recurrences r, 
               recurrence_interval_types t
        where  recurrence_id   = recurrence_row.recurrence_id
        and    r.interval_type = t.interval_type;
        
        -- Week has to be handled specially.
        -- Start with the beginning of the week containing the start date.
        if v_interval_name = 'week' 
	then
            v_current_date := next_day(v_current_date - to_interval(7,'days'),'SUNDAY');
            v_days_of_week := recurrence_row.days_of_week;
            v_days_length  := char_length(v_days_of_week);
        end if;
        
        -- Check count to prevent runaway in case of error
        v_instance_count := 0;

	-- A feature: we only care about the date when populating the database for reccurrence.
        while v_instance_count < 10000 and (date_trunc('day',v_last_date_done) <= date_trunc('day',v_stop_date))
        loop
            v_instance_count := v_instance_count + 1;
        
            -- Calculate next date based on interval type

	    -- Add next day, skipping every v_n_intervals
	    if v_interval_name = 'day' 
	    then
                v_current_date := v_current_date + to_interval(v_n_intervals,'days');
	    end if;
        
	    -- Add a full month, skipping by v_n_intervals months
            if v_interval_name = 'month_by_date' 
	    then
                v_current_date := add_months(v_current_date, v_n_intervals);
	    end if;

	    -- Add days so that the next date will have the same day of the week,  and week of the month
            if v_interval_name = 'month_by_day' then
                -- Find last day of month before correct month
                v_last_day := add_months(last_day(v_current_date), v_n_intervals - 1);
                -- Find correct week and go to correct day of week
                v_current_date := next_day(v_last_day + 
				              to_interval(7 * (to_number(to_char(v_current_date,'W'),'99')::INT - 1),
							  'days'),
                                            to_char(v_current_date, 'DAY'));
	    end if;

	    -- Add days so that the next date will have the same day of the week on the last week of the month
            if v_interval_name = 'last_of_month' then
                -- Find last day of correct month
                v_last_day := last_day(add_months(v_current_date, v_n_intervals));
                -- Back up one week and find correct day of week
                v_current_date := next_day(v_last_day ::timestamp - to_interval(7,'days') :: timestamptz, to_char(v_current_date, 'DAY'));
	    end if;

	    -- Add a full year (12 months)
            If v_interval_name = 'year' then
                v_current_date := add_months(v_current_date, 12 * v_n_intervals);
	    end if;

            -- Deal with custom function
            if v_interval_name = 'custom' then

	        -- JS: Execute a dynamically created query on the fly...
	        FOR rec_execute IN
		EXECUTE 'select ' || recurrence_row.custom_func 
				    || '(' || quote_literal(v_current_date)
				    || ',' || v_n_intervals || ') as current_date'
		LOOP
		     v_current_date := rec_execute.current_date;
		END LOOP;

            end if;
        
            -- Check to make sure we are not going past Trunc because dates are not integral
            exit when date_trunc('day',v_current_date) > date_trunc('day',v_stop_date);
        
            -- Have to handle week specially
            if v_interval_name = 'week' then
                -- loop over days_of_week extracting each day number
                -- add day number and insert
                v_days_index := 1;
                v_week_date  := v_current_date;
                while v_days_index <= v_days_length loop
                    v_day_num   := SUBSTR(v_days_of_week, v_days_index, 1);
                    v_week_date := (v_current_date ::timestamp + to_interval(v_day_num,'days')) :: timestamptz;
	           if date_trunc('day',v_week_date) > date_trunc('day',v_start_date) 
		       and date_trunc('day',v_week_date) <= date_trunc('day',v_stop_date) then
                         -- This is where we add the event
                         v_event_id := acs_event__new_instance(
                              insert_instances__event_id,					   -- event_id
                              date_trunc('day',v_week_date) - date_trunc('day',v_event_date)    -- offset
                         );
                         v_last_date_done := v_week_date;

                     else if date_trunc('day',v_week_date) > date_trunc('day',v_stop_date) 
		          then
                             -- Gone too far
                             exit;
			  end if;

                     end if;

                     v_days_index := v_days_index + 2;

                 end loop;

                 -- Now move to next week with repeats.
                v_current_date := (v_current_date :: timestamp + to_interval(7 * v_n_intervals,'days')) :: timestamptz;
            else
                -- All other interval types
                -- This is where we add the event
                v_event_id := acs_event__new_instance(
                    insert_instances__event_id,						    -- event_id 
                    date_trunc('day',v_current_date ::timestamp) - date_trunc('day',v_event_date ::timestamp)   -- offset
                );
                v_last_date_done := v_current_date;
            end if;
        end loop;
        
        update recurrences
        set    db_populated_until = v_last_date_done
        where  recurrence_id      = recurrence_row.recurrence_id;

	return 0;
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('time_interval__copy','interval_id,offset;0');

--
-- procedure time_interval__copy/2
--
CREATE OR REPLACE FUNCTION time_interval__copy(
   copy__interval_id integer,
   copy__offset interval -- default 0

) RETURNS integer AS $$
-- time_intervals.interval_id%TYPE
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

-- Allow editing only future recurrences

create or replace function acs_event__recurrence_timespan_edit (
        p_event_id integer,
        p_start_date timestamptz,
        p_end_date timestamptz
) returns integer as $$
DECLARE
BEGIN
    return acs_event__recurrence_timespan_edit (
           p_event_id,
           p_start_date,
           p_end_date,
           't');
END;
$$ LANGUAGE plpgsql;

create or replace function acs_event__recurrence_timespan_edit (
        p_event_id integer,
       p_start_date timestamptz,
       p_end_date timestamptz,
       p_edit_past_events_p boolean
) returns integer as $$
DECLARE
        v_timespan                   RECORD;
        v_one_start_date             timestamptz;
        v_one_end_date               timestamptz;
BEGIN
        -- get the initial offsets
        select start_date,
               end_date into v_one_start_date,
               v_one_end_date
        from time_intervals, 
             timespans, 
             acs_events 
        where time_intervals.interval_id = timespans.interval_id
          and timespans.timespan_id = acs_events.timespan_id
          and event_id=p_event_id;
raise notice 'DAVEB RECURRENCE edit_past_events_p = % start date = %',p_edit_past_events_p,p_start_date;
        FOR v_timespan in
            select *
            from time_intervals
            where interval_id in (select interval_id
                                  from timespans 
                                  where timespan_id in (select timespan_id
                                                        from acs_events 
                                                        where recurrence_id = (select recurrence_id 
                                                                               from acs_events where event_id = p_event_id)))
           and (p_edit_past_events_p = 't' or start_date >= v_one_start_date)
        LOOP
                PERFORM time_interval__edit(v_timespan.interval_id, 
                                            v_timespan.start_date + (p_start_date - v_one_start_date), 
                                            v_timespan.end_date + (p_end_date - v_one_end_date));
        END LOOP;

        return p_event_id;
END;

$$ LANGUAGE plpgsql;
