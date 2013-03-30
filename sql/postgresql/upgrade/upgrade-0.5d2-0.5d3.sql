-- backwards compatible 13 param version
CREATE OR REPLACE FUNCTION acs_event__new ( 
       integer,
       varchar,
       text,
       boolean,
       text,
       integer,
       integer,
       integer,
       varchar,
       timestamptz,
       integer,
       varchar,
       integer
) RETURNS integer AS $$
BEGIN
       return acs_event__new($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,null);
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('acs_event__new','event_id;null,name;null,description;null,html_p;null,status_summary;null,timespan_id;null,activity_id;null,recurrence_id;null,object_type;acs_event,creation_date;now(),creation_user;null,creation_ip;null,context_id;null,package_id;null');

--
-- procedure acs_event__new/14
--
CREATE OR REPLACE FUNCTION acs_event__new(
   new__event_id integer,          -- default null,
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
   new__package_id integer         -- default null

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
            (event_id, name, description, html_p, status_summary, activity_id, timespan_id, recurrence_id)
       values
            (v_event_id, new__name, new__description, new__html_p, new__status_summary, new__activity_id, new__timespan_id,
             new__recurrence_id);

       return v_event_id;

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('acs_event__new_instance','event_id,date_offset');

--
-- procedure acs_event__new_instance/2
--
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
            event_row.activity_id,    -- activity_id
            event_row.recurrence_id,  -- recurrence_id
	    'acs_event',	      -- object_type (default)
	    now(),		      -- creation_date (default)
            object_row.creation_user, -- creation_user
            object_row.creation_ip,   -- creation_ip
            object_row.context_id,     -- context_id
            object_row.package_id     -- context_id
	    );

      return v_event_id;

END;
$$ LANGUAGE plpgsql;

