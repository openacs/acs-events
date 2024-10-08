
<property name="context">{/doc/acs-events/ {ACS Events}} {ACS Events Design Documentation}</property>
<property name="doc(title)">ACS Events Design Documentation</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h2>ACS Events Design Documentation</h2>

by <a href="mailto:smeeks\@arsdigita.com">W. Scott Meeks</a>
<hr>
<h3>I. Essentials</h3>
<ul>
<li>Tcl script directory (link to the API browser page for the
package)</li><li>PL/SQL file (link to the API browser page for the package)</li><li>Data model: <a href="/doc/sql/display-sql?url=acs-events-create.sql&amp;package_key=acs-events">
acs-events-create.sql</a>
</li><li><a href="requirements">Requirements document</a></li><li>ER diagram</li><li>Transaction flow diagram</li>
</ul>
<h3>II. Introduction</h3>
<p>The ACS events service is primarily intended for use by writers
of application packages and other service packages. The service
allows developers to specify and manipulate relationships (possibly
recurring) between a <em>set of intervals in time</em>, an
<em>activity</em>, and an arbitrary number of <em>parties</em>. An
activity can be associated with an arbitrary number of ACS
<em>objects</em>.</p>
<p>The package doesn&#39;t provide for any interpretation of
events, leaving that up to the applications that use the service.
In particular, the package assumes that permissioning, and the
related concept of approval, will be handled by the application.
Similarly, notification is also the responsibility of the
application (but probably via another service package.) Likewise,
the package provides no UI support.</p>
<p>Possible application domains include include calendaring, room
reservation, scheduling, project management, and event
registration.</p>
<p>The requirements break the functionality into four main areas:
events, time intervals, activities, and recurrences. The package
meets the requirements for each of these areas in the following
ways:</p>
<p>
<strong>Events:</strong> The service creates a new subtype of
acs_object: acs_event. It creates an auxiliary table for mapping
events to parties. It provides an API for manipulating and querying
events and their associated time interval sets, activities,
recurrences, and parties.</p>
<p>
<strong>Time Intervals:</strong> The service creates tables for
storing time intervals and sets of time intervals. It provides an
API for manipulating and querying time intervals and time interval
sets.</p>
<p>
<strong>Activities:</strong> The service creates a new subtype
of acs_object: acs_activity. It creates an auxiliary table for
mapping activities to objects. It provides an API for manipulating
activities, their properties, and their associated objects.</p>
<p>
<strong>Recurrences:</strong> The service creates a table for
storing information on how an event recurs, including how the event
recurs and when it stops recurring. It provides an API for
manipulating recurrence information and recurring events. This
includes a function to insert event recurrences in such a way as to
reasonably limit the amount of information stored in the DB for a
particular event. This is done by only partially populating the
recurrences for certain events. The service also provides a view
which simplifies querying to find partially populated recurring
events that need recurrences added to the DB.</p>
<h3>III. Historical Considerations</h3>
<p>There are number of historical considerations surrounding the
design of recurring events. Much of the current design can be
traced pack to the original <a href="http://www.arsdigita.com/doc/calendar/design.html">ACS 3.4
Calendar Package design</a>, though the design has been cleaned up,
modified to fit with the new events data model and slightly
expanded.</p>
<p>One key consideration is exactly how recurring events are
supported. There are two main choices. One choice is to insert only
a single row for each recurring event, regardless of the number of
times it will recur. This row contains all the information
necessary to compute whether or not that event would recur on a
particular day. The alternative is to insert a row for each
recurrence.</p>
<p>I favored the second approach for the following reasons. First,
one tradeoff is time vs. space. Computation, particularly if it
might need to be done in Tcl and not solely in the database, is
relatively expensive compared to storing additional information in
the database. In many cases, the only information that will need to
be stored for recurrences is the date and time of the
recurrence.</p>
<p>I think it may be faster in Oracle even with a stored proc, at
least with the month view and possibly the week view as well. This
is because with 1 row per recurrence, the month and week view
queries can pull all the relevant items out at once and can take
advantage of the index on the start_date column to optimize the
query. With the stored proc, it would be necessary to iterate over
each day (up to 42 in the month view), calling the check repeat
proc for each base repeating item who&#39;s repeat_until date was
still relevant, and then effectively constructing the item to be
displayed.</p>
<p>Another reason is that the first approach, to insert only a
single row, seems to require a significantly more complex design.
Thus the design, implementation and eventual maintenance time would
be greater. It becomes even more complex when you allow exceptions.
Now you need to maintain a separate table of exceptions and it
becomes necessary to check through the exceptions table every time
the check repeat proc is called. It the worst case, every
recurrence is an exception, so you&#39;re essentially back to 1 row
per recurrence, plus all the added complexity of using the check
repeat proc.</p>
<p>This is not an unreasonable possibility and is in fact how Sloan
operates. Each class is represented as a recurring item and it is
very common for each instance to have a different set of files
attached to it.</p>
<p>However, there are drawbacks to this approach. First, it will be
more difficult to handle events that recur indefinitely. Second
(but related) is that safeguards will need to be put in place to
prevent pathological (accidental or intentional) cases from
swamping the database.</p>
<p>In the ACS 3.4 Calendar Package, this was partially resolved in
the following way. Users are limited to looking no more than 10
years in the past or 10 years in the future. (Actually, this is a
system parameter and can be set more or less restrictive, but the
default is 10 years.) This seemed reasonable given that other
systems seem to have arbitrary, implementation driven limits. Yahoo
and Excite have arbitrary limits between about 1970 and 2030. Palm
seems to have no lower limit, but an upper limit of 2031.</p>
<p>The 4.0 ACS Events service doesn&#39;t enforce a particular
policy to prevent problems, but it does provide mechanisms that a
well-designed application can use. The keys are the
<strong>event_recurrence.insert_events</strong> procedure and the
<strong>partially_populated_events</strong> view.</p>
<p>
<strong>insert_events</strong> takes either an event_id or a
recurrence_id and a cutoff date. It either uses the recurrence_id,
or gets it from the event_id, to retrieve the information needed to
generate the dates of the recurrences. When inserting a recurring
event for the first time, the application will need to call
<strong>insert_events</strong> with a reasonable populate_until
date. For calendar, for example, this could be sysdate + the
lookahead limit.</p>
<p>It is the application&#39;s responsibility to determine if
additional events need to be inserted into the DB to support the
date being used in a query to view events. The application can do
this by querying on partially_populated_events, using the date in
question and any other limiting conditions to determine if there
are any recurrences that might recur on the date in question which
have not been populated up to that date. To insure reasonable
performance, the application needs to be clever about tracking the
current date viewed and the maximum date viewed so as to minimize
the number of times this query is performed. The application should
also pick a date reasonably far in the future for insert additional
instances.</p>
<p>Another historical consideration is the choice of values for
event_recurrence.interval_type. The original choice for the 3.4
calendar was based on the Palm DateBook which seemed fairly
inclusive (covering both Yahoo Calendar and Excite Planner) though
it didn&#39;t capture some of the more esoteric cases covered by
Outlook or (particularly) Lotus Notes. The Events service maintains
the original choices, but adds an additional choice,
'custom', which, when combined with the custom_func column,
allows an application to generate an arbitrary recurrence function.
The function must take a date and a number of intervals as
arguments and return a new date greater than the given date. The
number of intervals is guaranteed to be a positive integer.</p>
<p>For the days_of_week column, the representation chosen, a
space-delimited list of integers, has a number of advantages.
First, it is easy and reasonably efficient to generate the set of
dates corresponding to the recurrences.
<strong>insert_events</strong> takes each number in the list in
turn and adds it to the date of the beginning of the week. Second,
the Tcl and Oracle representations are equivalent and the
translations to and from UI are straightforward. In particular, the
set of checkboxes corresponding to days of the week are converted
directly into a Tcl list which can be stored directly into the
DB.</p>
<h3>IV. Competitive Analysis</h3>
<p>Since this is a low level service package, there is no direct
competition.</p>
<h3>V. Design Tradeoffs</h3>
<p>Because this is a service package, tradeoffs were made only in
areas of interest to developers. Indeed, the main design tradeoff
was made at the very beginning, namely that this would be a
narrowly-focussed service package. This had consequences in the
following areas:</p>
<h4>Maintainability</h4>
<p>To simplify the package as much as possible, a number of
possible features were left to be handled by other services or by
the applications using the events package. This includes
controlling access to events via permissions, providing an approval
process, and providing support for notification. permissions app
dependent, approval via workflow, separate notification service
package</p>
<p>There was one significant, fairly complex feature that was
included, namely the support for recurrences. It could have been
left to the application developers or another service package.
However, because the 3.4 Calendar package already had a model for
recurring calendar items, it was straightforward to adapt this
model for the rest of the events data model. The advantage of this
is that this code is now in one place with no need for applications
to reinvent the wheel. It also means that there is a consistent
model across the toolkit.</p>
<h4>Reusability</h4>
<p>Much thought was given to the needs of applications most likely
to use this service, such as calendar, events, and room
reservations. This has led to a well defined API which should be
reusable by most applications that are concerned by events.</p>
<h4>Testability</h4>
<p>Because the API consists of well defined PL/SQL functions, it
should be fairly easy to build a test suite using the PL/SQL
testing tools.</p>
<h3>VI. Data Model and API Discussion</h3>
<p>The data model and PL/SQL API encapsulate the four main
abstractions defined in the ACS Events service: events, time
interval sets, activities, and recurrences. At present, there is no
Tcl API, but if desired one could be added consisting primarily of
wrappers around PL/SQL functions and procedures.</p>
<h4>Events</h4>
<p>This is the main abstraction in the package.
<kbd>acs_event</kbd> is a subtype of <kbd>acs_object</kbd>. In
addition to the <kbd>acs_events</kbd> table, there is an
<kbd>acs_event_party_map</kbd> table which maps between parties and
events. The <kbd>acs_event</kbd> package defines <kbd>new</kbd>,
<kbd>delete</kbd>, various procedures to set attributes and
<kbd>recurs_p</kbd> indicating whether or not a particular event
recurs.</p>
<h4>Time Interval Sets</h4>
<p>Because time interval sets are so simple, there is no need to
make them a subtype of <kbd>acs_object</kbd>. Interval sets are
represented with one table to represent time intervals, and a
second table which groups intervals into sets, with corresponding
PL/SQL packages defining <kbd>new</kbd>, <kbd>delete</kbd>, and
additional manipulation functions.</p>
<h4>Activities</h4>
<p>This is the secondary abstraction in the package.
<kbd>acs_activity</kbd> is a subtype of <kbd>acs_object</kbd>. In
addition to the <kbd>acs_activities</kbd> table, there is an
<kbd>acs_activity_object_map</kbd> table which maps between objects
and activities. The <kbd>acs_activity</kbd> package defines
<kbd>new</kbd>, <kbd>delete</kbd>, and various procedures to set
attributes and mappings.</p>
<h4>Recurrences</h4>
<p>Since recurrences are always associated with events, there
seemed to be no need to make them objects. The information that
determines how an event recurs is stored in the
<kbd>event_recurrences</kbd> table.</p>
<p>The <kbd>event_recurrence</kbd> package defines <kbd>new</kbd>,
<kbd>delete</kbd>, and other procedures related to recurrences. The
key procedure is <kbd>insert_events</kbd>.</p>
<p>A view, <kbd>partially_populated_events</kbd>, is created which
hides some of the details of retrieving recurrences that need to
populated further.</p>
<!--
    <li> Data management components: procedures that provide a stable
    interface to database objects and legal transactions - the latter
    often correspond to tasks. </li>

<p>
Remember that the correctness, completeness, and stability of the API
and interface are what experienced members of our audience are looking
for.  This is a cultural shift for us at aD (as of mid-year 2000), in
that we&#39;ve previously always looked at the data models as key, and
seldom spent much effort on the API (e.g. putting raw SQL in pages to
handle transactions, instead of encapsulating them via procedures).
Experience has taught us that we need to focus on the API for
maintainability of our systems in the face of constant change. 
</p>


<p>
The data model discussion should do more than merely display the SQL
code, since this information is already be available via a link in the
"essentials" section above.  Instead, there should be a high-level
discussion of how your data model meets your solution requirements:
why the database entities were defined as they are, and what
transactions you expect to occur. (There may be some overlap with the
API section.)  Here are some starting points:
</p>

<ul>
    <li> The data model discussion should address the intended usage
of each entity (table, trigger, view, procedure, etc.) when this
information is not obvious from an inspection of the data model
itself. </li>

    <li> If a core service or other subsystem is being used (e.g., the
new parties and groups, permissions, etc.) this should also be
mentioned. </li>

    <h4>Transactions</h4>

    <li> Discuss modifications which the database may undergo from
    your package. Consider grouping legal transactions according to
    the invoking user class, i.e. transactions by an ACS-admin, by
    subsite-admin, by a user, by a developer, etc.  </li>

</ul>

--><h3>VIII. User Interface</h3>
<p>This package does not provide a UI.</p>
<h3>IX. Configuration/Parameters</h3>
<p>There are no parameters for this package.</p>
<h3>X. Future Improvements/Areas of Likely Change</h3>
<p>If the system presently lacks useful/desirable features, note
details here. You could also comment on non-functional improvements
to the package, such as usability.</p>
<p>Note that a careful treatment of the earlier "competitive
analysis" section can greatly facilitate the documenting of
this section.</p>
<h3>XI. Authors</h3>
<ul>
<li>System owner: <a href="mailto:smeeks\@arsdigita.com">W. Scott
Meeks</a>
</li><li>System creator: <a href="mailto:smeeks\@arsdigita.com">W. Scott
Meeks</a>
</li><li>Documentation author: <a href="mailto:smeeks\@arsdigita.com">W.
Scott Meeks</a>
</li>
</ul>
<h3>XII. Revision History</h3>
<table cellpadding="2" cellspacing="2" width="90%" bgcolor="#EFEFEF">
<tr bgcolor="#E0E0E0">
<th width="10%">Document Revision #</th><th width="50%">Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr><tr>
<td>0.1</td><td>Creation</td><td>11/20/2000</td><td>W. Scott Meeks</td>
</tr>
</table>
