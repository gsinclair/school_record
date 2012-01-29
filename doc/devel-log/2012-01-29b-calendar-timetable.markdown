# Calendar and Timetable

I now have a note command and a note report.  Notes are good, except that their
file representation is ugly, but that will be fixed in time.

The next logical thing to do is lessons, but lessons have an awareness of what
classes I see on a given day, and when there are public holidays, staff days,
etc.  That requires the design and implementation of Calendar and Timetable.

It's not easy to sit here and envisage every little requirement of these
classes, but some things that they must be able to do between them:

* Convert between "calendar" dates (2012-04-13) and "school" dates (Sem1-6B-Thu).
* Know what classes I have on a certain day.
* Know what days school is on (accounting for staff days, public holidays, etc.)
* Iterate over every school day between one date and another.

The tie-in for lessons is that if I run `sr edit today` then it will open a text
editor with today's lessons ready to accept my input.  And if today is a public
holiday and I run that, then it will give me an error.

Here is some quotes from the doc/brainstorm.md:

> Calendar knows about the school year.  An instance of calendar represents a
  single calendar year.  It takes its configuration from calendar.yaml.  That
  could be as simple as knowing the start and end date of each term.  It can
  determine the weeks (1A, 2B, ...) from that, and can translate between calendar
  dates (2012-06-11) and term dates (Sem1-18B-Tue).  It can tell me: what's the
  next/previous school day, or iterate over a series of school days.  I suppose a
  value object is needed to represent the school day: SchoolDay, with accessors
  `term_date` and `calendar_date`, perhaps. SchoolDay.parse(str) would be good: it
  can handle parse("3 Jun") or parse("19A-Mon") or parse("Sem2-10B-Thu").

> Calendar should know about Staff Days, public holidays, etc.  Things like
  excursions, assemblies, etc. are "obstacles".  Obstacles can be postponed or
  cancelled.  Public holidays and Staff Days cannot.

> Calendar knows that Semester 1 encompasses Terms 1 and 2, and Semester 2
  encompasses Terms 3 and 4.  *Reporting periods* are not so easy to define,
  though.

> I foresee Calendar having nested classes Semester, Term, CalendarEntry (to
  define public holidays etc.) and ReportingPeriod.  A single Calendar instance
  should contain all the instances of these things that it needs.  The Calendar
  class should be able to handle all sorts of useful queries about these things.

> Timetable is configured from timetable.yaml and knows when I see each class.  It
  probably doesn't need to know what period; only the day.  Does it need to know I
  see Year 10 twice on Thursday A, for instance?  We'll see.

> Timetable ties in with ClassList.  Each class has a short label, a label, and a
  full name, e.g. "10", "10MT1" and "10 Mathematics 1", or something.  I will
  probably only use the short label, but it makes sense to store the others.  If
  another teacher used this and had two Year 7 classes, for instance, they could
  use the short labels to distinguish them, like 7A and 7B.

> Obstacle should be a pretty simple class, maybe just a value object with the
  date, the class label, and the reason. Although I didn't think so before, the
  Calendar object should probably just own an array of Obstacles. It can then
  sensibly implement Calendar#lessons("5 May"), etc.

And here are examples of configuration:

    timetable.yaml:

        WeekA:
         - Mon: "10,11,7,12"
         - Tue: "10,12,11,7"
         - Wed: "11,12,7,10"
         - Thu: "10,10,7,12"
         - Fri: "11,11,10,7"
        WeekB:
         - Mon: "10,7,12,11"
         - Tue: "10,12,12,7"
         - Wed: "12,11,10,7"
         - Thu: "10,10,7,11"
         - Fri: "10,7,12,11"

    calendar.yaml:

        Term1:
          - "2012-01-30"
          - "10 weeks"
        Term2:
          - "2012-04-25"    # making this up
          - "9 weeks"
        Term 3: ...
        Term 4: ...
        ReportingPeriods:
          - rp1: ["2012-01-30", "2012-05-21"]
          - rp2: ["2012-06-07", "2012-09-13"]
        StaffDays:
          - "2012-01-30"
          - "2012-01-31"
          - ...
        PublicHolidays:
          - "2012-04-25"
          - ...
        SpeechDay: "2012-12-07"

    obstacles.yaml:

        Term1:
          - ...
        Term2:
          - date: 3 June
            year: all
            reason: Public holiday (...)
          - date: 12B-Wed
            year: 7
            reason: Geography excursion
          - dates: ["9A-Mon", "9A-Thu"]
            year: 7
            reason: Exams
        Term3:
          - ...
        Term4:
          - ...


It won't be hard to implement a Timetable class, but what is its lifecycle?  How
and when does it get loaded?  How do other classes access it?  The Database is
the obvious answer, but is it a good answer?  I'm starting to feel the need for
a Config class.  But Database has the dev/test/prod architecture that we need...

    @db.timetable            # -> SR::Timetable
    @db.calendar             # -> SR::Calendar
    @db.obstacles            # -> SR::Obstacles

I imagine that the actual loading of the object would be done by
SR::Database::TimetableLoader to contain the mess.  (It's not just a YAML load
and that's it.)

Each of the three classes mentioned above would probably need a reference to the
database in case they need to refer to each other.  (Can't think of example
right now.)

Plan of action:

* Create the config files in the test database (in a Config directory this time,
  and move class-lists.yaml there) and symlink them from the dev database.
* Implement and test the classes, bit by bit, recording progress here.
* Hopefully see the bigger picture emerge of how these are going to be used and
  possibly interrelate.

## Iteration 1: files and directories

I've created a new layout for the test database.

    $ tree test/db
    +--db
        +--Config/
        |  +--calendar.yaml
        |  +--class-lists.yaml
        |  +--obstacles.yaml
        |  +--timetable.yaml
        +--notes.yaml

I need to update the code to take account of fact that class-lists.yaml is now
in Config.

