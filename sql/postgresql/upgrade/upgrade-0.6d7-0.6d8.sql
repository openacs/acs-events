select define_function_args('time_interval__copy','interval_id,offset;0');
select define_function_args('time_interval__delete','interval_id');
select define_function_args('time_interval__edit','interval_id,start_date;null,end_date;null');
select define_function_args('time_interval__eq','interval_1_id,interval_2_id');
select define_function_args('time_interval__overlaps_p','interval_id,start_date;null,end_date;null');
select define_function_args('time_interval__shift','interval_id,start_offset;0,end_offset;0');

select define_function_args('timespan__copy','timespan_id,offset');
select define_function_args('timespan__delete','timespan_id');
select define_function_args('timespan__exists_p','timespan_id');
select define_function_args('timespan__interval_delete','timespan_id,interval_id');
select define_function_args('timespan__join','timespan_id,start_date;null,end_date;null');
select define_function_args('timespan__join_interval','timespan_id,interval_id,copy_p;true');
select define_function_args('timespan__multi_interval_p','timespan_id');
select define_function_args('timespan__new','start_date;null,end_date;null');
select define_function_args('timespan__overlaps_interval_p','timespan_id,interval_id;null');
select define_function_args('timespan__overlaps_p','timespan_id,start_date;null,end_date;null');

select define_function_args('acs_event__new','event_id;null,name;null,description;null,html_p;null,status_summary;null,timespan_id;null,activity_id;null,recurrence_id;null,object_type;acs_event,creation_date;now(),creation_user;null,creation_ip;null,context_id;null,package_id;null');
select define_function_args('acs_event__delete','event_id');
select define_function_args('acs_event__delete_all_recurrences','recurrence_id;null');
select define_function_args('acs_event__delete_all','event_id');
select define_function_args('acs_event__get_name','event_id');
select define_function_args('acs_event__get_description','event_id');
select define_function_args('acs_event__get_html_p','event_id');
select define_function_args('acs_event__get_status_summary','event_id');
select define_function_args('acs_event__timespan_set','event_id,timespan_id');
select define_function_args('acs_event__recurrence_timespan_edit','event_id,start_date,end_date,edit_past_events_p');
select define_function_args('acs_event__activity_set','event_id,activity_id');
select define_function_args('acs_event__party_map','event_id,party_id');
select define_function_args('acs_event__party_unmap','event_id,party_id');
select define_function_args('acs_event__recurs_p','event_id');
select define_function_args('acs_event__instances_exist_p','recurrence_id');
select define_function_args('acs_event__get_value','parameter_name');
select define_function_args('acs_event__new_instance','event_id,date_offset');
select define_function_args('acs_event__insert_instances','event_id,cutoff_date;null');
select define_function_args('acs_event__shift','event_id;null,start_offset;0,end_offset;0');
select define_function_args('acs_event__shift_all','event_id;null,start_offset;0,end_offset;0');

select define_function_args('acs_activity__new','activity_id;null,name,description;null,html_p;f,status_summary;null,object_type;acs_activity,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');
select define_function_args('acs_activity__delete','activity_id');
select define_function_args('acs_activity__name','activity_id');
select define_function_args('acs_activity__edit','activity_id,name;null,description;null,html_p;null,status_summary;null');
select define_function_args('acs_activity__object_map','activity_id,object_id');
select define_function_args('acs_activity__object_unmap','activity_id,object_id');

select define_function_args('recurrence__new','interval_name,every_nth_interval,days_of_week;null,recur_until;null,custom_func;null');
select define_function_args('recurrence__delete','recurrence_id');
