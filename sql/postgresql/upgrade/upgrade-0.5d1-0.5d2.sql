create or replace function acs_event__get_html_p (
       --
       -- Returns html_p or html_p of the activity associated with the event if 
       -- html_p is null.
       --
       -- @author W. Scott Meeks
       --
       -- @param event_id id of event to get html_p for
       --
       -- @return The html_p or html_p of the activity associated with the event if html_p is null.
       --
       get_html_p__event_id integer
)
returns boolean as $$
declare
       v_html_p		acs_events.html_p%TYPE; 
begin
       select coalesce(e.html_p, a.html_p) into v_html_p
       from  acs_events e
       left join acs_activities a
       on (e.activity_id = a.activity_id)
       where e.event_id = get_html_p__event_id;

       return v_html_p;

end;
$$ language plpgsql;




-- added
select define_function_args('acs_event__get_status_summary','event_id');

--
-- procedure acs_event__get_status_summary/1
--
CREATE OR REPLACE FUNCTION acs_event__get_status_summary(
   get_status_summary__event_id integer

) RETURNS boolean AS $$
DECLARE
       v_status_summary		acs_events.status_summary%TYPE; 
BEGIN
       select coalesce(e.status_summary, a.status_summary) into v_status_summary
       from  acs_events e
       left join acs_activities a
       on (e.activity_id = a.activity_id)
       where e.event_id = get_status_summary__event_id;

       return v_status_summary;

END;
$$ LANGUAGE plpgsql;

