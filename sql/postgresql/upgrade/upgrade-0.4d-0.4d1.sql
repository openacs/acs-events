update acs_objects
set title = (select name
             from acs_events
             where event_id = object_id)
where object_type = 'acs_event';

update acs_objects
set title = (select name
             from acs_activities
             where activity_id = object_id)
where object_type = 'acs_activity';


drop function acs_event__new (integer,varchar,text,boolean,text,integer,integer,integer,varchar,timestamptz,integer,varchar,integer);



-- added
select define_function_args('acs_event__new','event_id;null,name;null,description;null,html_p;null,status_summary;null,timespan_id;null,activity_id;null,recurrence_id;null,object_type;acs_event,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');

--
-- procedure acs_event__new/13
--
CREATE OR REPLACE FUNCTION acs_event__new(
   new__event_id integer,                    -- default null,
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
   new__context_id integer         -- default null

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
            null		-- package_id
	    );
                
       insert into acs_events
            (event_id, name, description, html_p, status_summary, activity_id, timespan_id, recurrence_id)
       values
            (v_event_id, new__name, new__description, new__html_p, new__status_summary, new__activity_id, new__timespan_id,
             new__recurrence_id);

       return v_event_id;

END;
$$ LANGUAGE plpgsql;



drop function acs_activity__new (integer,varchar,text,boolean,text,varchar,timestamptz,integer,varchar,integer);



-- added
select define_function_args('acs_activity__new','activity_id;null,name,description;null,html_p;f,status_summary;null,object_type;acs_activity,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');

--
-- procedure acs_activity__new/10
--
CREATE OR REPLACE FUNCTION acs_activity__new(
   new__activity_id integer,                    -- default null,
   new__name varchar,
   new__description text,          -- default null,
   new__html_p boolean,            -- default 'f',
   new__status_summary text,       -- default null,
   new__object_type varchar,       -- default 'acs_activity'
   new__creation_date timestamptz, -- default now(),
   new__creation_user integer,     -- default null,
   new__creation_ip varchar,       -- default null,
   new__context_id integer         -- default null

) RETURNS integer AS $$
		 -- return acs_activities.activity_id%TYPE
DECLARE       
       v_activity_id		  acs_activities.activity_id%TYPE;
BEGIN
       v_activity_id := acs_object__new(
            new__activity_id,	   -- object_id
            new__object_type,	   -- object_type
            new__creation_date,    -- creation_date  
            new__creation_user,    -- creation_user
            new__creation_ip,	   -- creation_ip
            new__context_id,	   -- context_id
            't',		   -- security_inherit_p
            new__name,		   -- title
            null		   -- package_id
	    );

       insert into acs_activities
            (activity_id, name, description, html_p, status_summary)
       values
            (v_activity_id, new__name, new__description, new__html_p, new__status_summary);

       return v_activity_id;

END;
$$ LANGUAGE plpgsql; 


drop function acs_activity__edit (integer,varchar,text,boolean,text);



-- added
select define_function_args('acs_activity__edit','activity_id,name;null,description;null,html_p;null,status_summary;null');

--
-- procedure acs_activity__edit/5
--
CREATE OR REPLACE FUNCTION acs_activity__edit(
   edit__activity_id integer,
   edit__name varchar,       -- default null,
   edit__description text,   -- default null,
   edit__html_p boolean,     -- default null
   edit__status_summary text -- default null

) RETURNS integer AS $$
DECLARE
BEGIN

       update acs_activities
       set    name        = coalesce(edit__name, name),
              description = coalesce(edit__description, description),
              html_p      = coalesce(edit__html_p, html_p),
              status_summary = coalesce(edit__status_summary, status_summary)
       where activity_id  = edit__activity_id;

       update acs_objects
       set    title = coalesce(edit__name, name)
       where activity_id  = edit__activity_id;

       return 0;

END;
$$ LANGUAGE plpgsql;
