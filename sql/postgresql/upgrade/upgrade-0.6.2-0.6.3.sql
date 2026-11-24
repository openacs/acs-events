-- Add names only to signatures verified against the current install SQL.
-- Prefix names to avoid collisions with the aliases in legacy bodies.
do $$
declare
    target record;
    definition text;
begin
    for target in
        with expected(function_name, input_types, input_names) as (
            values
            ('acs_activity__delete', 'integer', 'activity_id'),
            ('acs_activity__edit', 'integer,varchar,text,boolean,text', 'activity_id,name,description,html_p,status_summary'),
            ('acs_activity__name', 'integer', 'activity_id'),
            ('acs_activity__new', 'integer,varchar,text,boolean,text,varchar,timestamptz,integer,varchar,integer', 'activity_id,name,description,html_p,status_summary,object_type,creation_date,creation_user,creation_ip,context_id'),
            ('acs_activity__object_map', 'integer,integer', 'activity_id,object_id'),
            ('acs_activity__object_unmap', 'integer,integer', 'activity_id,object_id'),
            ('acs_event__activity_set', 'integer,integer', 'event_id,activity_id'),
            ('acs_event__delete', 'integer', 'event_id'),
            ('acs_event__delete_all', 'integer', 'event_id'),
            ('acs_event__delete_all_recurrences', 'integer', 'recurrence_id'),
            ('acs_event__get_description', 'integer', 'event_id'),
            ('acs_event__get_html_p', 'integer', 'event_id'),
            ('acs_event__get_name', 'integer', 'event_id'),
            ('acs_event__get_status_summary', 'integer', 'event_id'),
            ('acs_event__get_value', 'varchar', 'parameter_name'),
            ('acs_event__instances_exist_p', 'integer', 'recurrence_id'),
            ('acs_event__party_map', 'integer,integer', 'event_id,party_id'),
            ('acs_event__party_unmap', 'integer,integer', 'event_id,party_id'),
            ('acs_event__recurs_p', 'integer', 'event_id'),
            ('acs_event__timespan_set', 'integer,integer', 'event_id,timespan_id'),
            ('timespan__delete', 'integer', 'timespan_id'),
            ('timespan__exists_p', 'integer', 'timespan_id'),
            ('timespan__interval_delete', 'integer,integer', 'timespan_id,interval_id'),
            ('timespan__join', 'integer,timestamptz,timestamptz', 'timespan_id,start_date,end_date'),
            ('timespan__join_interval', 'integer,integer,boolean', 'timespan_id,interval_id,copy_p'),
            ('timespan__multi_interval_p', 'integer', 'timespan_id'),
            ('timespan__overlaps_interval_p', 'integer,integer', 'timespan_id,interval_id'),
            ('timespan__overlaps_p', 'integer,timestamptz,timestamptz', 'timespan_id,start_date,end_date'),
            ('time_interval__delete', 'integer', 'interval_id'),
            ('time_interval__edit', 'integer,timestamptz,timestamptz', 'interval_id,start_date,end_date'),
            ('time_interval__eq', 'integer,integer', 'interval_1_id,interval_2_id'),
            ('time_interval__overlaps_p', 'timestamptz,timestamptz,timestamptz,timestamptz', 'start_1,end_1,start_2,end_2')
        )
        select p.oid, n.nspname, p.proname, arguments.signature
          from expected e
          join pg_proc p on p.oid = to_regprocedure(
              format('%I.%I(%s)', current_schema(), e.function_name, e.input_types))
          join pg_namespace n on n.oid = p.pronamespace
          cross join lateral (
              select string_agg(
                         format('%I %s', 'arg_' || a.arg_name, format_type(a.type_oid, null)),
                         ', ' order by a.position) as signature
                from unnest(p.proargtypes::oid[], string_to_array(e.input_names, ','))
                     with ordinality as a(type_oid, arg_name, position)
          ) arguments
         where p.prokind = 'f'
           and p.proargnames is null
           and p.proargmodes is null
           and p.pronargdefaults = 0
           and p.pronargs = cardinality(string_to_array(e.input_names, ','))
           and p.pronargs = (
               select count(*) from acs_function_args a
                where a.function = upper(e.function_name)
           )
           and e.input_names = (
               select string_agg(lower(a.arg_name), ',' order by a.arg_seq)
                 from acs_function_args a
                where a.function = upper(e.function_name)
           )
           and not exists (
               select 1 from pg_proc other
                where other.proname = p.proname
                  and other.pronargs = p.pronargs
                  and other.oid <> p.oid
           )
    loop
        definition := pg_get_functiondef(target.oid);
        execute format('CREATE OR REPLACE FUNCTION %I.%I(%s)',
                       target.nspname, target.proname, target.signature)
                || substr(definition, strpos(definition, chr(10)));
    end loop;
end;
$$;
