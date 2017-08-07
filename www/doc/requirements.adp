
<property name="context">{/doc/acs-events {ACS Events}} {ACS Events Service Requirements}</property>
<property name="doc(title)">ACS Events Service Requirements</property>
<master>
<h2>ACS Events Service Requirements</h2>

by W. Scott Meeks
<h3>I. Introduction</h3>
<p>This document records the requirements for a new ACS Events
service package. This package is intended to provide basic
functionality which can be used in a consistent manner by other
service and application packages. The events service specifies
relationships (possibly recurring) between a set of time intervals
time, an activity, and an arbitrary number of parties. An activity
can be associated with an arbitrary number of ACS objects.</p>
<h3>II. Vision Statement</h3>
<p>The ACS Events package will provide support for other services
and applications that require representing this sort of
relationship between time, parties, activities, and objects. Such
applications include the generation of calendar objects, room
reservations, event registration, and possibly workflow.</p>
<p>The service needs to support recurring events. Many applications
need to represent blocks of time within a given day that are
intended to be be repeated regularly on subsequent days. The
service should support representing the most common types of
recurrences: daily, weekly, monthly, et cetera. It should also
provide for custom recurrences.</p>
<p>Having a single service for this functionality provides a number
of business advantages:</p>
<ul>
<li>It saves work and increases quality; applications that deal
with time don&#39;t have to "re-invent the wheel" but
instead can use a common, tested code base.</li><li>It improves consistency; the same API will be used in different
applications.</li><li>It simplifies integration; since a common data model is used to
represent events, different applications can more easily share
related information.</li>
</ul>
<p>For example, the events service could support a room reservation
application that is integrated with an application which maintains
users&#39;s personal and group calendars. Suppose Stephanie uses
the room reservation application to reserve the Boston 1st floor
conference room on 11/11 from 1pm to 2pm for Ern, Allen, and Alan.
The events service will add a new event for this time slot, add a
mapping to Ern, Allen, and Alan, and an activity for the meeting.
This activity will map to the conference room. Now to get a
calendar item to appear on Ern, Allen, and Alan&#39;s calendars,
the reservation application can simply pass the event to the
calendar application which adds a mapping between the activity and
a new calendar item.</p>
<h3>III. ACS Events Package Overview</h3>
<p>There are four main areas of functionality in the events
package: events, time intervals, activities, and recurrences. The
service depends upon the ACS object and parties systems.</p>
<h4>III.A Events</h4>
<p>An <strong>event</strong> is an activity associated with a
temporal interval or several such intervals. Events may have
additional attributes as well. Examples of events include:
"hitchhiking from 4pm to 5pm", "attending the InSync
concert from 11pm to 1am at the Enormodome", et cetera. Events
are represented by designating the associated activity together
with a set of time intervals indicating when that activity is to
occur.</p>
<p>An event can optionally be mapped to a set of parties
representing groups or individuals that have some connection to the
event.</p>
<p>The service provides an API for manipulating events.</p>
<p>An event is a relationship which maps parties and an activity to
a set of time intervals. The relationship between a particular
event can be one to many with parties. Time intervals can be open
ended.</p>
<p>Activities contain a name, a description, and an optional link
to related information. Ativites can be mapped one to many to ACS
objects. The object mapped to a particular activity can be another
activity or event.</p>
<h4>III.B Time Interval Sets</h4>
<p>A time interval set is a range of moments at which an event can
occur. A single time interval is of the form "from 3:00pm to
3:17pm on 11/20/2000". A time interval set is of the form
"from 3:00pm to 3:17pm and from 4:30pm to 4:45pm on
11/20/2000". A set of time intervals has two advantages: (i)
it allows for the representation of temporally gappy events such as
conferences, which end one day and pick up again the next, and (ii)
if implemented properly, it allows a simplification of the above
account of events, as now an event can be identified with a pair of
an activity together with a time interval set.</p>
<p>The service provides an API for manipulating time interval
sets.</p>
<h4>III.C Activities</h4>
<p>An <strong>activity</strong> is a thing that a person or people
do, usually represented by a gerundic phrase, such as
"biking", "reserving a room", "travelling
to Bhutan to achieve enlightenment", et cetera. Activities are
represented via a name and a description. An activity can
optionally be mapped to a set of ACS objects.</p>

The service provides an API for manipulating activities.
<h4>III.D Recurring Events</h4>
<p>Consider an event, say, an activity A performed on day D at time
T. The ACS Events service allows applications to generate new
events which are the same activity A performed on different days in
the future, but at the same time of day T; such events are said to
be <strong>recurrences</strong> of the primary event. Recurrences
can happen on a daily, weekly, monthly, yearly or custom basis. The
start and end dates of recurrences can be uniformly offset.</p>
<h4>III.E Dependencies</h4>
<p>The service depends on the ACS object model and on our parties
system. Event is a subtype of acs_object. The ACS Events service
maps between the event object, a time interval set, an activity,
and an arbitrary number of parties.</p>
<h3>IV. Use-cases and User-scenarios</h3>
<p><em>Determine the types or classes of users who would use the
system, and what their experience would be like at a high-level.
Sketch what their experience would be like and what actions they
would take, and how the system would support them.</em></p>
<h3>V. Related Links</h3>
<ul>
<li>System/Package "coversheet" TBD</li><li>Design document TBD</li><li>Developer&#39;s guide TBD</li><li>User&#39;s guide TBD</li><li><a href="http://www.arsdigita.com/doc/calendar/">3.4 calendar
package documentation</a></li><li><a href="http://www.arsdigita.com/doc/cr.html">Reservations
module</a></li><li><a href="http://www.arsdigita.com/ad-training/acs40-training">Problem Set 2
revised for ACS 4.0</a></li><li>Test plan TBD</li>
</ul>
<h3>VI.A Data Model Requirements</h3>
<p><strong>10.10 Events</strong></p>
<p>
<strong>10.10.10</strong> The data model represents activities
associated with sets of time intervals.</p>
<p>
<strong>10.10.20</strong> Events can optionally be associated
with parties.</p>
<p>
<strong>10.10.30&gt;</strong> Events can optionally recur.</p>
<p><strong>10.20 Time Interval Sets</strong></p>
<p>
<strong>10.20.10</strong> A time interval consists of a start
time and an end time.</p>
<p>
<strong>10.20.20</strong> A time interval set consists of a set
of associated time intervals.</p>
<p>
<strong>10.20.30</strong> Individual time intervals can be open
ended. That is, the beginning time, ending time, or both may be
null. The exact meaning of a null time is application dependent.
However, as a suggestion, null end time could indicate events such
as holidays or birthdays that have no particular start time
associated with them. Null start time could indicate a due date.
Both times null could indicate some item that needs to be scheduled
in the future but does not yet have a set time.</p>
<p><strong>10.30 Activities</strong></p>
<p>
<strong>10.30.10</strong> An activity has a name and a
description.</p>
<p>
<strong>10.30.20</strong> An activity can be associated with a
set of ACS objects.</p>
<p>
<strong>10.30.30</strong> An event object can be a valid target
for an activity. This could indicate time dependencies, e.g. for
workflow or project management.</p>
<p><strong>10.50 Recurring Events</strong></p>
<p>
<strong>10.50.10</strong> The data model provides a table which
describes how to generate recurrences from a base event.</p>
<strong>10.50.20</strong>
 Recurring on a daily basis should be
supported.
<p>
<strong>10.50.30</strong> Recurring on a weekly basis should be
supported. For weekly recurrences, it should be possible to specify
exactly which days of the week.</p>
<p>
<strong>10.50.40</strong> Recurring every month on a particular
date should be supported.</p>
<p>
<strong>10.50.50</strong> Recurring every month on a particular
day of a particular week should be supported.</p>
<p>
<strong>10.50.60</strong> If a date in the 4th or 5th week of a
month has been selected, then an option should be presented
allowing an item to recur on a particular day of the last week of a
month.</p>
<p>
<strong>10.50.70</strong> Recurring yearly on a particular date
should be supported.</p>
<p>
<strong>10.50.80</strong> The data model should allow an
application to provide a custom recurrence function.</p>
<p>
<strong>10.50.90</strong> It should be possible to specify an
end date for recurrences.</p>
<p>
<strong>10.50.100</strong> It should be possible to specify no
end date for recurrences.</p>
<p>
<strong>10.50.110</strong> The service should enforce reasonable
limits on the amount of data used to represent recurring events. In
other words, it should not be possible to fill the DB with
thousands of rows representing a single recurring event, even if it
recurs indefinitely.</p>
<p>
<strong>10.50.120</strong> The service should provide a view for
querying on those recurrences that aren&#39;t fully populated in
the DB.</p>
<h3>VI.B API Requirements</h3>
<p><strong>20.10 Event API</strong></p>
<p>
<strong>20.10.10</strong> The service supports adding an
event.</p>
<p>
<strong>20.10.15</strong> The service supports setting the time
interval set of an event.</p>
<p>
<strong>20.10.20</strong> The service supports setting the
activity of an event.</p>
<p>
<strong>20.10.30</strong> The service supports adding or
deleting a party mapping to an event.</p>
<p>
<strong>20.10.40</strong> The service supports deleting a
complete event.</p>
<p><strong>20.20 Time Interval Set API</strong></p>
<p>
<strong>20.20.10</strong> The service supports adding a time
interval set.</p>
<p>
<strong>20.20.20</strong> The service supports adding a time
interval to a set.</p>
<p>
<strong>20.20.30</strong> The service supports updating the
start or end dates of a time interval.</p>
<p>
<strong>20.20.40</strong> The service supports deleting a time
interval from a set.</p>
<p>
<strong>20.20.50</strong> The service supports counting the
number of time intervals in a set.</p>
<p>
<strong>20.20.60</strong> The service supports determining if a
given interval overlaps a particular time interval set.</p>
<p><strong>20.30 Activity API</strong></p>
<p>
<strong>20.30.10</strong> The service supports creating an
activity.</p>
<p>
<strong>20.30.20</strong> The service supports deleting an
activity.</p>
<p>
<strong>20.30.30</strong> The service supports updating the name
of an activity.</p>
<p>
<strong>20.30.40</strong> The service supports updating the
description of an activity.</p>
<p>
<strong>20.30.50</strong> The service supports adding or
deleting an object mapping to an event.</p>
<p><strong>20.50 Recurrence API</strong></p>
<p>
<strong>20.50.10</strong> The service supports adding
recurrences of an event.</p>
<p>
<strong>20.50.20</strong> The service supports deleting
recurrences of an event.</p>
<p>
<strong>20.50.30</strong> The service supports uniformly
offsetting the start or end times of time intervals of recurrences
of an event.</p>
<p>
<strong>20.50.40</strong> The service supports determining if an
event recurs.</p>
<h3>VII. Design and Implementation Notes</h3>
<h4>VII.A 3.4 Calendar Package</h4>
<p>The <a href="http://www.arsdigita.com/doc/calendar/">3.4
calendar package</a> provides some ideas for the design and
implementation of the events service. One way to look at the
service is as a distillation of the components of the calendar data
model and implementation which would be common to any event-based
application. In particular, I anticipate the table for recurring
information will be very similar to the calendar data model for
recurring items.</p>
<h4>VII.B Problem Set 2</h4>
<p>Another way to look at this events service is as an elaboration
of the scheduling service in <a href="http://www.arsdigita.com/ad-training/acs40-training">Problem Set 2
revised for ACS 4.0</a>. The main differences are allowing multiple
time intervals, and a one to many relationship with parties and
objects. Thus the data model will have the core event_id, and
repeat_id in the event subtype of acs_object. Time Intervals will
be in a separate table. The parties column and object column will
be split out into separate mapping tables.</p>
<h4>VII.C Recurring Events</h4>
<p>There is a very important tradeoff to be made in the
implementation of recurring events. <a href="http://dev.arsdigita.com/doc/calendar/design.html#tradeoffs">Calendar
Design Tradeoffs</a> details this tradeoff as applied to the 3.4
calendar package.</p>
<p>There are two main choices for supporting recurring events. One
choice is to insert only a single row for each recurring event,
regardless of the number of times it will recur. This row contains
all the information necessary to compute whether or not that event
would recur on a particular day. The alternative is to insert a row
for each recurrence.</p>
<p>I favor the second approach for the following reasons. First,
one tradeoff is time vs. space. Computation, particularly if it
might need to be done in Tcl and not solely in the database, is
relatively expensive compared to storing additional information in
the database. In many cases, the only information that will need to
be stored for recurrences is the date and time of the
recurrence.</p>
<p>Another reason is that the first approach, to insert only a
single row, seems to require a significantly more complex design.
Thus the design, implementation and eventual maintenance time would
be greater.</p>
<p>This approach will also make it much easier to handle exceptions
to recurrences and individualizing the objects associated with
instances of events.</p>
<p>However, there are drawbacks to this approach. First, it will be
more difficult to handle events that recur indefinitely. Second
(but related) is that safeguards will need to be put in place to
prevent pathological (accidental or intentional) cases from
swamping the database.</p>
<p>Another issue is that when populating the DB with recurring
event instances, there is an application-level choice that the
service needs to support. This is the decision as to whether the
new event instances are mapped to the same object or to newly
created objects. For example, for the reservation application, the
instances should be mapped to the same room object. Alternately,
for the calendar application, the instances should be mapped to new
calendar events so that each instance can be modified
individually.</p>
<h3>VIII. Revision History</h3>
<table cellpadding="2" cellspacing="2" width="90%" bgcolor="#EFEFEF">
<tr bgcolor="#E0E0E0">
<th width="10%">Document Revision #</th><th width="50%">Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr><tr>
<td>0.1</td><td>Creation</td><td>11/13/2000</td><td>W. Scott Meeks</td>
</tr><tr>
<td>0.2</td><td>Revision, remove timezones, add multiple timespans</td><td>11/14/2000</td><td>W. Scott Meeks</td>
</tr><tr>
<td>0.3</td><td>Rename "scheduling" to "event handling".
Add activities. Renaming and updating requirements.</td><td>11/15/2000</td><td>W. Scott Meeks</td>
</tr><tr>
<td>0.4</td><td>Remove approval in favor of requiring applications to use
acs-workflow.</td><td>11/17/2000</td><td>W. Scott Meeks</td>
</tr><tr>
<td>0.5</td><td>Name of package changes from "Event Handling" to
"ACS Events".</td><td>11/17/2000</td><td>W. Scott Meeks</td>
</tr><tr>
<td>0.6</td><td>Clean up, clarification, rewording</td><td>12/08/2000</td><td>Joshua Finkler</td>
</tr>
</table>
<hr>
<address><a href="mailto:smeeks\@arsdigita.com">smeeks\@arsdigita.com</a></address>

Last modified: $Date$
