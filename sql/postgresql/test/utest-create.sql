-- packages/acs-events/sql/postgresql/test/utest-create.sql
--
-- Regression tests for timespan API
-- Separated from time_interval-test.sql
--
-- @author jowell@jsabino.com
--
-- @creation-date 2001-06-26
--
-- $Id$

-- /* 
-- GNU General Public License for utPLSQL
--     
-- Copyright (C) 2000 
-- Steven Feuerstein, steven@stevenfeuerstein.com
-- Chris Rimmer, chris@sunset.force9.co.uk
-- 
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program (see license.txt); if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-- */

-- JS: Ported/copied shamelessly from the utplsql package.  
-- JS: This package is grossly incomplete, but quite useful (for me, anyways). 



-- added
select define_function_args('ut_assert__expected','msg,check_this,against_this');

--
-- procedure ut_assert__expected/3
--
CREATE OR REPLACE FUNCTION ut_assert__expected(
   expected__msg varchar,
   expected__check_this varchar,
   expected__against_this varchar
) RETURNS varchar AS $$
DECLARE
BEGIN

      return expected__msg || 
	     ': expected ' ||
	     '''' ||
	     expected__against_this ||
	     '''' ||
	     ', got ' || 
	     '''' ||
	     expected__check_this ||
	     '''';

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('ut_assert__this','msg,check_this,null_ok;FALSE,raise_exc;FALSE');

--
-- procedure ut_assert__this/4
--
CREATE OR REPLACE FUNCTION ut_assert__this(
   this__msg varchar,
   this__check_this boolean,
   this__null_ok boolean,  -- default FALSE
   this__raise_exc boolean -- default FALSE

) RETURNS integer AS $$
DECLARE
BEGIN

      -- We always output the message (usually the result of the test)
      raise notice '%',this__msg;

      if not this__check_this
         or ( this__check_this is null
               and not this__null_ok )
      then

	 -- Raise an exception if a failure
         if this__raise_exc
         then
	    -- We should make the message more informative.
            raise exception 'FAILURE'; 
	 else
	    raise notice 'FAILURE, but forced to continue.';
         end if;

      end if;

      -- Continue if success;
      return 0;

END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__this/2
--
CREATE OR REPLACE FUNCTION ut_assert__this(
   this__msg varchar,
   this__check_this boolean
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__this(this_msg,this_check_this,'f','f');
     
END;
$$ LANGUAGE plpgsql;



-- added

--
-- procedure ut_assert__eq/5
--
CREATE OR REPLACE FUNCTION ut_assert__eq(
   eq__msg varchar,
   eq__check_this varchar,
   eq__against_this varchar,
   eq__null_ok boolean,  -- default FALSE,
   eq__raise_exc boolean -- defaultFALSE

) RETURNS integer AS $$
DECLARE
BEGIN
	return ut_assert__this (
		 ut_assert__expected (eq__msg, eq__check_this, eq__against_this),
		 eq__check_this = eq__against_this,
		 eq__null_ok,
		 eq__raise_exc
		 );
	
END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__eq/3
--
CREATE OR REPLACE FUNCTION ut_assert__eq(
   eq__msg varchar,
   eq__check_this varchar,
   eq__against_this varchar
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__eq(eq__msg,eq__check_this,eq__against_this,'f','f');

END;
$$ LANGUAGE plpgsql;




-- added
select define_function_args('ut_assert__b2v','bool_exp');

--
-- procedure ut_assert__b2v/1
--
CREATE OR REPLACE FUNCTION ut_assert__b2v(
   bool_exp boolean
) RETURNS varchar AS $$
DECLARE
BEGIN

      if bool_exp
      then
         return 'true';
      else if not bool_exp
           then
              return 'false';
           else
              return 'null';
           end if;
      end if;

END;
$$ LANGUAGE plpgsql;



--
-- procedure ut_assert__eq/5
--
CREATE OR REPLACE FUNCTION ut_assert__eq(
   eq__msg varchar,
   eq__check_this boolean,
   eq__against_this boolean,
   eq__null_ok boolean,  -- default false
   eq__raise_exc boolean -- default false

) RETURNS integer AS $$
DECLARE
BEGIN
     
     return  ut_assert__this (
		       ut_assert__expected (
				 eq__msg,
				 ut_assert__b2v(eq__check_this),
				 ut_assert__b2v(eq__against_this)
				 ),
		       ut_assert__b2v (eq__check_this) = ut_assert__b2v (eq__against_this),
		       eq__null_ok,
		       eq__raise_exc
		       );
			

END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__eq/3
--
CREATE OR REPLACE FUNCTION ut_assert__eq(
   eq__msg varchar,
   eq__check_this boolean,
   eq__against_this boolean
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__eq(eq__msg,eq__check_this,eq__against_this,'f','f');

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('ut_assert__eq','msg,check_this,against_this,null_ok;false,raise_exc;false');

--
-- procedure ut_assert__eq/5
--
CREATE OR REPLACE FUNCTION ut_assert__eq(
   eq__msg varchar,
   eq__check_this timestamptz,
   eq__against_this timestamptz,
   eq__null_ok boolean,  -- default false
   eq__raise_exc boolean -- default false

) RETURNS integer AS $$
DECLARE
      c_format		constant varchar := 'MONTH DD, YYYY HH24MISS';
      v_check		varchar;
      v_against		varchar;
BEGIN

      v_check := to_char (eq__check_this, c_format);
      v_against := to_char (eq__against_this, c_format);

      return ut_assert__this (
                       ut_assert__expected (eq__msg, v_check, v_against),
		       v_check = v_against,
		       eq__null_ok,
		       eq__raise_exc
		       );

END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__eq/3
--
CREATE OR REPLACE FUNCTION ut_assert__eq(
   eq__msg varchar,
   eq__check_this timestamptz,
   eq__against_this timestamptz
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__eq(eq__msg,eq__check_this,eq__against_this,'f','f');

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('ut_assert__ieqminus','msg,query1,query2,minus_desc,raise_exc');

--
-- procedure ut_assert__ieqminus/5
--
CREATE OR REPLACE FUNCTION ut_assert__ieqminus(
   ieqminus__msg varchar,
   ieqminus__query1 varchar,
   ieqminus__query2 varchar,
   ieqminus__minus_desc varchar,
   ieqminus__raise_exc boolean
) RETURNS varchar AS $$
DECLARE
      v_query		      varchar;
      rec_tableminus	      record;
      v_eq		      boolean := 't';

BEGIN

	v_query := ' ( ' ||
		   ieqminus__query1 ||
		   ' except ' ||
		   ieqminus__query2 ||
		   ' ) ' ||
		   ' union ' ||
		   ' ( ' ||
		   ieqminus__query2 ||
		   ' except ' ||
		   ieqminus__query1 ||
		   ' ) ';

	for  rec_tableminus in execute v_query;

	   -- Will not go in this loop if v_query result is null, so
	   -- we need to set the default value of v_eq to true.
	   if found
	   then
	      v_eq := 'f';
	   end if;

	   -- One is enough
	   exit;

	end loop;

      return ut_assert__this (
                       ut_assert__expected (ieqminus__msg || ' ' || ieqminus__minus_desc,
					    ieqminus__query1, 
					    ieqminus__query2
					    ),
		       v_eq,
		       'f',
		       ieqminus__raise_exc
		       );

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('ut_assert__eqtable','msg,check_this,against_this,check_where;null,against_where;null,raise_exc;false');

--
-- procedure ut_assert__eqtable/6
--
CREATE OR REPLACE FUNCTION ut_assert__eqtable(
   eqtable__msg varchar,
   eqtable__check_this varchar,
   eqtable__against_this varchar,
   eqtable__check_where varchar,   -- default null
   eqtable__against_where varchar, -- default null
   eqtable__raise_exc boolean      -- default false

) RETURNS integer AS $$
DECLARE
BEGIN
      return ut_assert__ieqminus (eqtable__msg,
			  'SELECT * FROM ' || eqtable__check_this || '  WHERE ' ||
			  coalesce (eqtable__check_where, '1=1'),
			  'SELECT * FROM ' || eqtable__against_this || '  WHERE ' ||
			  coalesce (eqtable__against_where, '1=1'),
			  'Table Equality',
			  eqtable__raise_exc
			  );
END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__eqtable/3
--
CREATE OR REPLACE FUNCTION ut_assert__eqtable(
   eqtable__msg varchar,
   eqtable__check_this varchar,
   eqtable__against_this varchar
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__eqtable(eqtable__msg,eqtable__check_this,eqtable__against_this,null,null,'f');

END;
$$ LANGUAGE plpgsql;




-- added
select define_function_args('ut_assert__eqtabcount','msg,check_this,against_this,check_where;null,against_where;null,raise_exc;false');

--
-- procedure ut_assert__eqtabcount/6
--
CREATE OR REPLACE FUNCTION ut_assert__eqtabcount(
   eqtabcount__msg varchar,
   eqtabcount__check_this varchar,
   eqtabcount__against_this varchar,
   eqtabcount__check_where varchar,   -- default null
   eqtabcount__against_where varchar, -- default null
   eqtabcount__raise_exc boolean      -- default false

) RETURNS integer AS $$
DECLARE
BEGIN
      return ut_assert__ieqminus (eqtabcount__msg,
			  'SELECT COUNT(*) FROM ' || eqtabcount__check_this || '  WHERE ' ||
			  coalesce (eqtabcount__check_where, '1=1'),
			  'SELECT COUNT(*) FROM ' || eqtabcount__against_this || '  WHERE ' ||
			  coalesce (eqtabcount__against_where, '1=1'),
			  'Table Count Equality',
			  eqtabcount__raise_exc
			  );
END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__eqtabcount/3
--
CREATE OR REPLACE FUNCTION ut_assert__eqtabcount(
   eqtabcount__msg varchar,
   eqtabcount__check_this varchar,
   eqtabcount__against_this varchar
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__eqtabcount(eqtabcount__msg,eqtabcount__check_this,eqtabcount__against_this,null,null,'f');

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('ut_assert__eqquery','msg,check_this,against_this,raise_exc;null');

--
-- procedure ut_assert__eqquery/4
--
CREATE OR REPLACE FUNCTION ut_assert__eqquery(
   eqquery__msg varchar,
   eqquery__check_this varchar,
   eqquery__against_this varchar,
   eqquery__raise_exc boolean -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
      return ut_assert__ieqminus (eqquery__msg,
			          eqquery__check_this,
				  eqquery__against_this,
				  'Query Equality',
				  eqquery__raise_exc
				  );
END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__eqquery/3
--
CREATE OR REPLACE FUNCTION ut_assert__eqquery(
   eqquery__msg varchar,
   eqquery__check_this varchar,
   eqquery__against_this varchar
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__eqquery(eqquery__msg,eqquery__check_this,eqquery__against_this,'f');

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('ut_assert__isnotnull','msg,check_this,null_ok;false,raise_exc;false');

--
-- procedure ut_assert__isnotnull/4
--
CREATE OR REPLACE FUNCTION ut_assert__isnotnull(
   isnotnull__msg varchar,
   isnotnull__check_this varchar,
   isnotnull__null_ok boolean,  -- default false
   isnotnull__raise_exc boolean -- default false

) RETURNS integer AS $$
DECLARE
BEGIN
      return ut_assert__this (
	        'IS NOT NULL: ' || isnotnull__msg,
		isnotnull__check_this IS NOT NULL,
		isnotnull__null_ok,
		isnotnull__raise_exc
		);
END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__isnotnull/2
--
CREATE OR REPLACE FUNCTION ut_assert__isnotnull(
   isnotnull__msg varchar,
   isnotnull__check_this varchar
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__isnotnull(isnotnull__msg,isnotnull__check_this,'f','f');

END;
$$ LANGUAGE plpgsql;




-- added
select define_function_args('ut_assert__isnull','msg,check_this,null_ok;false,raise_exc;false');

--
-- procedure ut_assert__isnull/4
--
CREATE OR REPLACE FUNCTION ut_assert__isnull(
   isnull__msg varchar,
   isnull__check_this varchar,
   isnull__null_ok boolean,  -- default false
   isnull__raise_exc boolean -- default false

) RETURNS integer AS $$
DECLARE
BEGIN
      return ut_assert__this (
	        'IS NULL: ' || isnull__msg,
		isnull__check_this IS NULL,
		isnull__null_ok,
		isnull__raise_exc
		);
END;
$$ LANGUAGE plpgsql;


-- Overload for calls with default values


--
-- procedure ut_assert__isnull/2
--
CREATE OR REPLACE FUNCTION ut_assert__isnull(
   isnull__msg varchar,
   isnull__check_this varchar
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__isnull(isnull__msg,isnull__check_this,'f','f');

END;
$$ LANGUAGE plpgsql;



--
-- procedure ut_assert__isnotnull/4
--
CREATE OR REPLACE FUNCTION ut_assert__isnotnull(
   isnotnull__msg varchar,
   isnotnull__check_this boolean,
   isnotnull__null_ok boolean,  -- default false
   isnotnull__raise_exc boolean -- default false

) RETURNS integer AS $$
DECLARE
BEGIN
      return ut_assert__this (
	        'IS NOT NULL: ' || isnotnull__msg,
		isnotnull__check_this IS NOT NULL,
		isnotnull__null_ok,
		isnotnull__raise_exc
		);
END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__isnotnull/2
--
CREATE OR REPLACE FUNCTION ut_assert__isnotnull(
   isnotnull__msg varchar,
   isnotnull__check_this boolean
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__isnotnull(isnotnull__msg,isnotnull__check_this,'f','f');

END;
$$ LANGUAGE plpgsql;



--
-- procedure ut_assert__isnull/4
--
CREATE OR REPLACE FUNCTION ut_assert__isnull(
   isnull__msg varchar,
   isnull__check_this boolean,
   isnull__null_ok boolean,  -- default false
   isnull__raise_exc boolean -- default false

) RETURNS integer AS $$
DECLARE
BEGIN
      return ut_assert__this (
	        'IS NULL: ' || isnull__msg,
		isnull__check_this IS NULL,
		isnull__null_ok,
		isnull__raise_exc
		);
END;
$$ LANGUAGE plpgsql;

-- Overload for calls with default values


--
-- procedure ut_assert__isnull/2
--
CREATE OR REPLACE FUNCTION ut_assert__isnull(
   isnull__msg varchar,
   isnull__check_this boolean
) RETURNS integer AS $$
DECLARE
BEGIN

      return ut_assert__isnull(isnull__msg,isnull__check_this,'f','f');

END;
$$ LANGUAGE plpgsql;






