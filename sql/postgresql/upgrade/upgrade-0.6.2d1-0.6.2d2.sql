
DROP function if exists
acs_event__new(integer, character varying, text, boolean, text, integer, integer, integer, character varying, timestamp with time zone, integer, character varying, integer, integer, varchar);

--
-- procedure acs_event__new/14-18
--
     -- Creates a new event (20.10.10)
     --
     -- @author W. Scott Meeks
     --
     -- @param event_id          id to use for new event
     -- @param name              Name of the new event
     -- @param description       Description of the new event
     -- @param html_p            Is the description HTML?
     -- @param status_summary    Optional additional status line to display
     -- @param timespan_id       initial time interval set
     -- @param activity_id       initial activity
     -- @param recurrence_id     id of recurrence information
     -- @param object_type       'acs_event'
     -- @param creation_date     default now()
     -- @param creation_user     acs_object param
     -- @param creation_ip       acs_object param
     -- @param context_id        acs_object param
     -- @param package_id        acs_object param
     -- @param location          location
     -- @param related_link_url  URL
     -- @param related_link_text anchor for URL
     -- @param redirect_to_rel_link_p activation flag
     --
     -- @return The id of the new event.

select define_function_args('acs_event__new','event_id;null,name;null,description;null,html_p;null,status_summary;null,timespan_id;null,activity_id;null,recurrence_id;null,object_type;acs_event,creation_date;now(),creation_user;null,creation_ip;null,context_id;null,package_id;null,location;null,related_link_url;null,related_link_text;null,redirect_to_rel_link_p;null');

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
   new__location varchar default NULL,
   new__related_link_url varchar default NULL,
   new__related_link_text varchar default NULL,
   new__redirect_to_rel_link_p boolean default NULL

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
	    activity_id, timespan_id, recurrence_id, location,
	    related_link_url, related_link_text, redirect_to_rel_link_p)
       values
            (v_event_id, new__name, new__description, new__html_p, new__status_summary,
	    new__activity_id, new__timespan_id, new__recurrence_id, new__location,
	    new__related_link_url, new__related_link_text, new__redirect_to_rel_link_p);

       return v_event_id;

END;
$$ LANGUAGE plpgsql;


--
-- procedure acs_event__insert_instances/2
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
            event_row.activity_id,    -- activity_id`
            event_row.recurrence_id,  -- recurrence_id
	    'acs_event',	      -- object_type (default)
	    now(),		      -- creation_date (default)
            object_row.creation_user, -- creation_user
            object_row.creation_ip,   -- creation_ip
            object_row.context_id,    -- context_id
            object_row.package_id,    -- package_id
	    event_row.location,        -- location
	    event_row.related_link_url,      -- related_link_url
	    event_row.related_link_text,     -- related_link_text
	    event_row.redirect_to_rel_link_p -- redirect_to_rel_link_p
	    );

      return v_event_id;
END;
$$ LANGUAGE plpgsql;
