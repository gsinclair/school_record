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

## Iteration 2: Timetable (and SchoolDay)

I'll start with Timetable: nice and easy.  Here's the config I planted.  It is
my 2012 timetable.

    WeekA:
      Mon: "10,11,7,12"
      Tue: "10,12,11,7"
      Wed: "11,12,7,10"
      Thu: "10,10,7,12"
      Fri: "11,11,10,7"
    WeekB:
      Mon: "10,7,12,11"
      Tue: "10,12,12,7"
      Wed: "12,11,10,7"
      Thu: "10,10,7,11"
      Fri: "10,7,12,11"

So a Timetable has a Week A and Week B.  Do I need a Week class?  Basically, the
interactions I need with Timetable are:

* timetable.lessons(schoolday) -> ['10', '12', '12', '7']

That's it, actually.  Timetable shouldn't do anything smart.  It's up to another
class, like Lessons, to look out for holidays etc.

    class Timetable
      @days -- array of 10 strings (the timetable cycle has 10 days)
      Timetable.from_yaml(file)
      lessons(schoolday)

That means I need to implement the SchoolDay class.  It represents both forms of
date.  The parsing is left to Calendar, as in @calendar.schoolday(string)

    class SchoolDay
      date       # -> Date
      semester   # -> 1 or 2
      term       # -> 1..4
      week       # -> 1..20  (more like 1..18 or 1..19)
      day        # -> "Mon", "Tue", ...
      month      # -> "Jan", "Feb", ...
      year       # -> 2012, ...
      day_of_cycle  # -> 1..10
      a_or_b     # -> "A", "B"
      to_s       # -> "Mon 11A (2012-09-28)"
      sem_date   # -> "Mon 11A" or "Sem2 Mon 11A" (if :semester => true)

SchoolDay needs access to a Calendar to do its work.  It always assumes the
current year (e.g. 2012).  I guess I need to call SchoolDay.calendar=() before
doing anything.

* No! SchoolDay is a dumb object and believes whatever you tell it.  Here is how
  it works:

    sd = SchoolDay.new( Date.new(2012,2,21), 1, 4)   # term 1, week 4
    sd.day            # Tue
    sd.semester       # 1     (before June)
    sd.weekstr        # "4B"
    sd.to_s           # "Tue 4B (21 Feb)"
    sd.day_of_cycle   # 6     (calculated from day and fact that it's Week B)
    # etc.

So _that_ means I need Calendar!  I was trying to start with an easy class.  I
guess I can implement Timetable and test it using some artificially created
SchoolDay objects.  It will be a simple class anyway.

For the record:

    class Calendar
      schoolday(string)   "6 Jun" or "2012-06-01" or "11A-Mon" or
                          "11A Mon" or "Sem2-11A-Mon" or "Sem2 11A Mon"

(_Later_...) OK, I've implemented and tested Timetable _and_ SchoolDay.
Timetable works as mentioned above.  Here's a snippet from its test.


    db = SR::Database.test
    timetable = db.timetable
    date = Date.new(2012, 2, 13)   # Mon 13 Feb 2012
    sd01 = SR::DO::SchoolDay.new(date + 0,  1, 3)
    Eq timetable.lessons(sd01), ['10','11','7','12']

So Timetable and SchoolDay, two dumb classes, are complete.  I can work on
Calendar now.

Note: Timetable is SR::Timetable and SchoolDay is SR::DO::SchoolDay.  Maybe that
DomainObjects namespace won't last forever, but the distinguishing feature
between Timetable and SchoolDay is that Timetable comes from a configuration
file and needs to be loaded by the database.

## Iteration 2: Calendar

Configuration (Config/calendar.yaml) as it is in the test database as of today.
Some details may be wrong but it's close to correct for 2012.

    Term1:
      - "2012-01-30"
      - "10 weeks"
      - "2012-04-05"
    Term2:
      - "2012-04-26"
      - "9 weeks"
      - "2012-06-22"
    Term 3:
      - "2012-07-17"
      - "10 weeks"
      - "2012-09-17"
    Term 4:
      - "2012-10-08"
      - "9 weeks"
      - "2012-12-07"
    StaffDays:
      - "2012-01-30"
      - "2012-01-31"
      - "2012-06-08"
      - "2012-12-06"
      - "2012-12-07"
    PublicHolidays:
      - "2012-04-06"
      - "2012-04-09"
      - "2012-04-25"
      - "2012-06-11"
    SpeechDay: "2012-12-05"

From this, I can see that Calendar will need a Term class to look after the
terms.  A Term class will have:

* term number (1..4)
* starting week (1 or 11, mostly)
* start and end dates
* number of weeks (probably not needed, but I'll chuck it in)

A Term object is responsible for resolving dates...

Actually, I'm not sure how it will be implemented.  Test-driven design will
probably help here.

The one thing I know about Calendar is that it implements Calendar#schoolday(str).
By setting up some tests for that, I can work on the implementation. Hopefully
once that works, ideas for other methods, in this class or others, will sprout.

_Later..._

In working on the implementation of Calendar#schoolday(str), I decided a Term
class was necessary.  It looks like this:

    @term = Term.new(2, '2012-04-23', '2012-06-22')
    @term.number                      # -> 2
    @term.semester                    # -> 1
    @term.number_of_weeks             # -> 9
    @term.include? '2012-05-01'       # => true
    @term.include? '2012-05-05'       # => false (it's a weekend)
    @term.date(week: 5, day: 2)       # -> Date.new(2012, 5, 22)
    @term.week_and_day '2012-06-13'   # -> [8, 3]  (Week 8, Wednesday)

Good stuff.  I'm committing the code (and this doc) up to this point and will
work on Calendar tomorrow.  I've started implementing Calendar, and it should be
much easier now with a decent Term class.  I need to model semesters somehow.
That will probably be with a Semester class that defers most of its work to
Term.  (Semester just needs to map, say, Week 13 to Term 2 Week 4.)  Anyway,
that's for tomorrow.
