-- packages/acs-events/sql/postgresql/activity-create.sql
--
-- @author W. Scott Meeks
-- @author Gary Jin (gjin@arsdigita.com)
--
-- @ported 2001-06-26
--
-- $Id$



--
-- procedure inline_0/0
--
CREATE OR REPLACE FUNCTION inline_0(

) RETURNS integer AS $$
DECLARE 
    attr_id acs_attributes.attribute_id%TYPE; 
BEGIN

    -- Event object     
    PERFORM acs_object_type__create_type ( 
       'acs_activity',   -- object_type
       'Activity',       -- pretty_name
       'Activities',     -- pretty_plural
       'acs_object',     -- supertype 
       'ACS_ACTIVITIES', -- table_name
       'ACTIVITY_ID',    -- id_column
       'null',	         -- package_name (default)
       'f',		 -- abstract_p (default)
       null,		 -- type_extension_table (default)
       null		 -- name_method (default)
    );

   -- Event attributes
    attr_id := acs_attribute__create_attribute (
       'acs_activity',     -- object_type
       'name',	           -- attribute_name
       'string',	   -- data_type
       'Name',	           -- pretty_name
       'Names',	           -- pretty_plural
       null,		   -- table_name (default)
       null,		   -- column_name (default)
       null,		   --  default_value (default)
       1,		   -- min_n_values (default)
       1,		   -- max_n_values (default)
       null,		   -- sort_order (default)
       'type_specific',    -- storage (default)
       'f'		   -- static_p (default)
    );

    attr_id := acs_attribute__create_attribute (
       'acs_activity',     -- object_type
       'description',	   -- attribute_name
       'string',	   -- data_type
       'Description',	   -- pretty_name
       'Descriptions',     -- pretty_plural
       null,		   -- table_name (default)
       null,		   -- column_name (default)
       null,		   --  default_value (default)
       1,		   -- min_n_values (default)
       1,		   -- max_n_values (default)
       null,		   -- sort_order (default)
       'type_specific',    -- storage (default)
       'f'		   -- static_p (default)
    );


    attr_id := acs_attribute__create_attribute (
       'acs_activity',     -- object_type
       'html_p',	   -- attribute_name
       'string',	   -- data_type
       'HTML?',	           -- pretty_name
       'HTML?',	           -- pretty_plural
       null,		   -- table_name (default)
       null,		   -- column_name (default)
       null,		   -- default_value (default)
       1,		   -- min_n_values (default)
       1,		   -- max_n_values (default)
       null,		   -- sort_order (default)
       'type_specific',    -- storage (default)
       'f'		   -- static_p (default)
    );

    attr_id := acs_attribute__create_attribute (
       'acs_activity',     -- object_type
       'status_summary',   -- attribute_name
       'string',	   -- data_type
       'Status Summary',   -- pretty_name
       'Status Summaries', -- pretty_plural
       null,		   -- table_name (default)
       null,		   -- column_name (default)
       null,		   --  default_value (default)
       1,		   -- min_n_values (default)
       1,		   -- max_n_values (default)
       null,		   -- sort_order (default)
       'type_specific',    -- storage (default)
       'f'		   -- static_p (default)
    );

    return 0;

END;
$$ LANGUAGE plpgsql;

select inline_0 ();
drop function inline_0 ();


-- The activities table
create table acs_activities (
    activity_id         integer
                        constraint acs_activities_fk
                        references acs_objects(object_id)
                        on delete cascade
                        constraint acs_activities_pk
                        primary key,
    name                varchar(255) not null,
    description         text,
    -- is the activity description written in html?
    html_p              boolean default 'f',
    status_summary      varchar(255)
);

comment on table acs_activities is '
    Represents what happens during an event
';
        

create table acs_activity_object_map (
    activity_id         integer
                        constraint acs_act_obj_mp_activity_id_fk
                        references acs_activities on delete cascade,
    object_id           integer
                        constraint acs_act_obj_mp_object_id_fk
                        references acs_objects(object_id) on delete cascade,
    constraint acs_act_obj_mp_pk
    primary key(activity_id, object_id)
);

comment on table acs_activity_object_map is '
    Maps between an activity and multiple ACS objects.
';

-- Activity API (all have activity_id as parameter))
--
--	new()
--	delete()
--
--	name()
--      edit (name,description,html_p,status_summary)
-- 
--      object_map (object_id)
--      object_unmap (object_id)




-- added
select define_function_args('acs_activity__new','activity_id;null,name,description;null,html_p;f,status_summary;null,object_type;acs_activity,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');

--
-- procedure acs_activity__new/10
--
     --
     -- Create a new activity
     --
     -- @author W. Scott Meeks
     --
     -- @param activity_id       Id to use for new activity
     -- @param name              Name of the activity 
     -- @param description       Description of the activity
     -- @param html_p            Is the description HTML?
     -- @param status_summary    Additional status note (optional)
     -- @param object_type       'acs_activity'
     -- @param creation_date     default now()
     -- @param creation_user     acs_object param
     -- @param creation_ip       acs_object param
     -- @param context_id        acs_object param
     --
     -- @return The id of the new activity.

CREATE OR REPLACE FUNCTION acs_activity__new(
   new__activity_id integer,       -- default null,
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




-- added
select define_function_args('acs_activity__delete','activity_id');

--
-- procedure acs_activity__delete/1
--
     -- Deletes an activity
     --
     -- @author W. Scott Meeks
     --
     -- @param activity_id      Id of activity to delete
     --
     -- @return 0 (procedure dummy)
     --

CREATE OR REPLACE FUNCTION acs_activity__delete(
   delete__activity_id integer

) RETURNS integer AS $$
DECLARE
BEGIN
       -- Cascade will cause delete from acs_activities 
       -- and acs_activity_object_map

       PERFORM acs_object__delete(delete__activity_id); 

       return 0;

END;
$$ LANGUAGE plpgsql;




-- added
select define_function_args('acs_activity__name','activity_id');

--
-- procedure acs_activity__name/1
--
     --
     -- Get name of this activity 
     --
     -- @author gjin@arsdigita.com
     --
     -- @param activity_id
     --
     -- @return Name of activity
     --

CREATE OR REPLACE FUNCTION acs_activity__name(
   name__activity_id integer

) RETURNS varchar AS $$
DECLARE 
       v_activity_name		acs_activities.name%TYPE;
BEGIN
       select  name
       into    v_activity_name
       from    acs_activities
       where   activity_id = name__activity_id;

       return  v_activity_name;

END;
$$ LANGUAGE plpgsql; 

         


-- added
select define_function_args('acs_activity__edit','activity_id,name;null,description;null,html_p;null,status_summary;null');

--
-- procedure acs_activity__edit/5
--
      -- Update the name or description of an activity
      --
      -- @author W. Scott Meeks
      --
      -- @param activity_id activity to update
      -- @param name        optional New name for this activity
      -- @param description optional New description for this activity
      -- @param html_p      optional New value of html_p for this activity
      -- @param status_summary optional New value of status_summary for this activity
      --
      -- @return 0 (procedure dummy)
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


-- added
select define_function_args('acs_activity__object_map','activity_id,object_id');

--
-- procedure acs_activity__object_map/2
--
     -- Adds an object mapping to an activity
     --
     -- @author W. Scott Meeks
     --
     -- @param activity_id       id of activity to add mapping to
     -- @param object_id         id of object to add mapping for
     --
     -- @return 0 (procedure dummy)
     --

CREATE OR REPLACE FUNCTION acs_activity__object_map(
   object_map__activity_id integer,
   object_map__object_id integer

) RETURNS integer AS $$
DECLARE
BEGIN
       insert into acs_activity_object_map
            (activity_id, object_id)
       values
            (object_map__activity_id, object_map__object_id);

       return 0;

END;
$$ LANGUAGE plpgsql;





-- added
select define_function_args('acs_activity__object_unmap','activity_id,object_id');

--
-- procedure acs_activity__object_unmap/2
--
     --
     -- Removes an object mapping to an activity
     --
     -- @author W. Scott Meeks
     --
     -- @param activity_id       id of activity to add mapping to
     -- @param object_id         id of object to add mapping for
     --
     -- @return 0 (procedure dummy)
     --
CREATE OR REPLACE FUNCTION acs_activity__object_unmap(
   object_unmap__activity_id integer,
   object_unmap__object_id integer

) RETURNS integer AS $$
DECLARE
BEGIN

       delete from acs_activity_object_map
       where  activity_id = object_unmap__activity_id
       and    object_id   = object_unmap__object_id;

       return 0;

END;
$$ LANGUAGE plpgsql;





