
DO $$
BEGIN
   update acs_object_types set
      table_name = lower(table_name),
      id_column = lower(id_column)
    where object_type in ('acs_activity', 'acs_event');
END$$;
