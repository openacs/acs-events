-- packages/acs-events/sql/postgres/oracle-compat-drop.sql
--
-- Drop functions that ease porting from Postgres to Oracle
--
-- @author jowell@jsabino.com
-- @creation-date 2001-06-26
--
-- $Id$

drop function dow_to_int(varchar);
drop function next_day(timestamp,varchar);
drop function add_months(timestamp,integer);
drop function last_day(timestamp);
drop function to_interval(integer,varchar);

