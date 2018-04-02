---
--- ADD COLUMN IF NOT EXISTS  was added in PostgreSQL 9.6
--- DO was added in 9.0, so we can use this already
---

DO $$ 
    BEGIN
        BEGIN
            ALTER TABLE acs_events ADD COLUMN location varchar(255);
        EXCEPTION
            WHEN duplicate_column THEN RAISE NOTICE 'column location exists already on table acs_events.';
        END;
    END
$$;

comment on column acs_events.location is '
    The location associated with this event.
';

DO $$
    DECLARE
        v_attr_exists integer = 0;  
        attr_id acs_attributes.attribute_id%TYPE;
    BEGIN
      select count(*) into v_attr_exists
      from acs_attributes where object_type = 'acs_event' and attribute_name = 'location';

      IF (v_attr_exists = 0) then
        attr_id := acs_attribute__create_attribute ( 
            'acs_event',         -- object_type
            'location',          -- attribute_name
            'string',            -- datatype
            'Location',          -- pretty_name
            'Locations',         -- pretty_plural
            null,                -- table_name (default)
            null,                -- column_name (default)
            null,                -- default_value (default)
            1,                   -- min_n_values (default)
            1,                   -- max_n_values (default)
            null,                -- sort_order (default)
            'type_specific',     -- storage (default)
            'f'                  -- static_p (default)
          );
      END IF;
    END
$$;

--
-- recreate the views
-- 
DROP view acs_events_dates;
CREATE view acs_events_dates as
select e.*, 
       start_date, 
       end_date
from   acs_events e,
       timespans s,
       time_intervals t
where  e.timespan_id = s.timespan_id
and    s.interval_id = t.interval_id;


DROP view acs_events_activities;
CREATE view acs_events_activities as
select event_id, 
       coalesce(e.name, a.name) as name,
       coalesce(e.description, a.description) as description,
       coalesce(e.html_p, a.html_p) as html_p,
       coalesce(e.status_summary, a.status_summary) as status_summary,
       e.activity_id,
       timespan_id,
       recurrence_id,
       location
from   acs_events e,
       acs_activities a
where  e.activity_id = a.activity_id;



--
-- procedure acs_event__new/14-15

select define_function_args('acs_event__new','event_id;null,name;null,description;null,html_p;null,status_summary;null,timespan_id;null,activity_id;null,recurrence_id;null,object_type;acs_event,creation_date;now(),creation_user;null,creation_ip;null,context_id;null,package_id;null,location;null');

CREATE OR REPLACE FUNCTION acs_event__new(
   new__event_id  integer,         -- default null,
   new__name varchar,              -- default null,
   new__description text,          -- default null,
   new__html_p boolean,            -- default null
   new__status_summary text,       -- default null
   new__timespan_id integer,       -- default null,
   new__activity_id integer,       -- default null,
   new__recurrence_id integer,     -- default null,
   new__object_type varchar,       -- default 'acs_event',
   new__creation_date timestamptz, -- default now(),
   new__creation_user integer,     -- default null,
   new__creation_ip varchar,       -- default null,
   new__context_id integer,        -- default null
   new__package_id integer,        -- default null
   new__location varchar default NULL

) RETURNS integer AS $$
	-- acs_events.event_id%TYPE
DECLARE
       v_event_id	    acs_events.event_id%TYPE;
BEGIN
       v_event_id := acs_object__new(
            new__event_id,	-- object_id
            new__object_type,	-- object_type
            new__creation_date, -- creation_date
            new__creation_user,	-- creation_user
            new__creation_ip,	-- creation_ip
            new__context_id,	-- context_id
            't',		-- security_inherit_p
            new__name,		-- title
            new__package_id	-- package_id
	    );

       insert into acs_events
            (event_id, name, description, html_p, status_summary,
	    activity_id, timespan_id, recurrence_id, location)
       values
            (v_event_id, new__name, new__description, new__html_p, new__status_summary,
	    new__activity_id, new__timespan_id, new__recurrence_id, new__location);

       return v_event_id;

END;
$$ LANGUAGE plpgsql;

DROP function if exists
acs_event__new(integer, character varying, text, boolean, text, integer, integer, integer, character varying, timestamp with time zone, integer, character varying, integer, integer);


CREATE OR REPLACE FUNCTION acs_event__new_instance(
   new_instance__event_id integer,
   new_instance__date_offset interval

) RETURNS integer AS $$
DECLARE
       event_row		  acs_events%ROWTYPE;
       object_row		  acs_objects%ROWTYPE;
       v_event_id		  acs_events.event_id%TYPE;
       v_timespan_id		  acs_events.timespan_id%TYPE;
BEGIN
       -- Get event parameters
       select * into event_row
       from   acs_events
       where  event_id = new_instance__event_id;

       -- Get object parameters                
       select * into object_row
       from   acs_objects
       where  object_id = new_instance__event_id;

       -- We allow non-zero offset, so we copy
       v_timespan_id := timespan__copy(event_row.timespan_id, new_instance__date_offset);

       -- Create a new instance
       v_event_id := acs_event__new(
	    null,                     -- event_id (default)
            event_row.name,           -- name
            event_row.description,    -- description
            event_row.html_p,         -- html_p
            event_row.status_summary, -- status_summary
            v_timespan_id,	      -- timespan_id
            event_row.activity_id,    -- activity_id`
            event_row.recurrence_id,  -- recurrence_id
	    'acs_event',	      -- object_type (default)
	    now(),		      -- creation_date (default)
            object_row.creation_user, -- creation_user
            object_row.creation_ip,   -- creation_ip
            object_row.context_id,    -- context_id
            object_row.package_id,    -- package_id
	    event_row.location        -- location
	    );

      return v_event_id;
END;
$$ LANGUAGE plpgsql;
