
DO $$
BEGIN
   update acs_attributes set
      datatype = 'boolean'
    where object_type = 'acs_activity'
      and attribute_name = 'html_p';

   update acs_attributes set
      datatype = 'boolean'
    where object_type = 'acs_event'
      and attribute_name = 'html_p';

   update acs_attributes set
      datatype = 'boolean'
    where object_type = 'acs_event'
      and attribute_name = 'redirect_to_rel_link_p';

END$$;
