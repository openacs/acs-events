begin;

   -- renaming a constraint is supported by Postgres since version 9.2
   alter table acs_activities rename constraint acs_activities_fk to acs_activities_activity_id_fk;
   alter table acs_activities rename constraint acs_activities_pk to acs_activities_activity_id_pk;

   alter table acs_events rename constraint acs_events_fk to acs_events_event_id_fk;
   alter table acs_events rename constraint acs_events_pk to acs_events_event_id_pk;

end;
