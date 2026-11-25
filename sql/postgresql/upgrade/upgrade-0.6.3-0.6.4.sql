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
            ('acs_event__shift', 'integer,integer,integer', 'event_id,start_offset,end_offset'),
            ('acs_event__shift_all', 'integer,integer,integer', 'event_id,start_offset,end_offset'),
            ('recurrence__delete', 'integer', 'recurrence_id'),
            ('time_interval__copy', 'integer,integer', 'interval_id,offset'),
            ('time_interval__shift', 'integer,integer,integer', 'interval_id,start_offset,end_offset'),
            ('timespan__copy', 'integer,integer', 'timespan_id,offset'),
            ('timespan__new', 'timestamptz,timestamptz', 'start_date,end_date')
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
           and not exists (
               select 1 from acs_function_args a
                where a.function = upper(e.function_name)
                  and (a.arg_seq < 1 or a.arg_seq > p.pronargs)
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
                  -- Allow the known companion overload only when its second
                  -- argument already distinguishes it from the registered one.
                  and not coalesce(
                      other.oid = to_regprocedure(format(
                          '%I.%I(%s)', n.nspname, e.function_name,
                          case e.function_name
                              when 'timespan__new' then 'integer,boolean'
                              when 'timespan__copy' then 'integer,interval'
                              when 'time_interval__copy' then 'integer,interval'
                              when 'time_interval__shift' then 'integer,interval,interval'
                              when 'acs_event__shift' then 'integer,interval,interval'
                              when 'acs_event__shift_all' then 'integer,interval,interval'
                          end))
                      and other.proargnames[2] <> ''
                      and other.proargnames[2] <> split_part(e.input_names, ',', 2)
                      and right(other.proargnames[2], length(split_part(e.input_names, ',', 2)) + 1)
                          <> '_' || split_part(e.input_names, ',', 2),
                      false)
           )
    loop
        definition := pg_get_functiondef(target.oid);
        execute format('CREATE OR REPLACE FUNCTION %I.%I(%s)',
                       target.nspname, target.proname, target.signature)
                || substr(definition, strpos(definition, chr(10)));
    end loop;
end;
$$;
