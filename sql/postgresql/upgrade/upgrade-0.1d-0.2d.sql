-- created by arjun@openforce.net 
-- from a bug fix by  Deds Castillo

drop function acs_event__recurrence_timespan_edit;

create function acs_event__recurrence_timespan_edit (
       integer,
       timestamp,
       timestamp
) returns integer as '
DECLARE
        p_event_id                      alias for $1;
        p_start_date                    alias for $2;
        p_end_date                      alias for $3;
        v_timespan                   RECORD;
        v_one_start_date             timestamp;
        v_one_end_date               timestamp;
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

        FOR v_timespan in
            select *
            from time_intervals
            where interval_id in (select interval_id
                                  from timespans 
                                  where timespan_id in (select timespan_id
                                                        from acs_events 
                                                        where recurrence_id = (select recurrence_id 
                                                                               from acs_events where event_id = p_event_id)))
        LOOP
                PERFORM time_interval__edit(v_timespan.interval_id, 
                                            v_timespan.start_date + (p_start_date - v_one_start_date), 
                                            v_timespan.end_date + (p_end_date - v_one_end_date));
        END LOOP;

        return p_event_id;
END;
' language 'plpgsql';
