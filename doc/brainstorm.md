school\_record brainstorm
=========================

The following paragraph was written in README.md.  It may end up being removed
from there, so it's copied here for safekeeping and idea development.

**school\_record** is an infant project to meet some of my needs as a high school
teacher:

* Record what I did with each class each day, including homework assigned
  and perhaps other useful specific (and reportable data).
* Produce easily read reports of what I've typed in.
    * What happened today/this week/etc.?
    * When did I start and finish each topic?
    * What homework have I assigned?
* Understand the school calendar and my timetable:
    * Know what days I see each class and prompt me that some entries are yet
      to be recorded.
    * Know what days school is in session.
    * Understand the school calendar: semesters, terms, weeks, reporting periods.
* Know about (via configuration) known obstacles to lessons, like exam blocks,
  staff days, excursions, etc.
    * Produce reports on lessons remaining for a given Year group this term, for
      instance, that takes known obstacles into account.
* (Maybe) Record simple tasks like writing exams so that reminders are given
  whenever I run the program, I get a gentle reminder.
    * In fact, it could be aware of exam-writing timetables, and give reminders
      about specific milestones (Draft 1, Draft 2, etc.).
* (Maybe) Provide basic calendar features for parent-teacher nights, exam
  blocks, etc.
* (Probably) Record notes about specific students, e.g. good work, missing
  equipment, etc.  These would be tied to a date, not a specific lesson.
    * Produce a list of all such notes grouped by student for a given class,
      making it easier to write reports.
* Store data in plain text on Dropbox allowing easy and fast (i.e. incremental)
  synchronisation between computers.



## Example command invocations

To demonstrate these ideas, here are some example command invocations.  It is
assumed that `sr` is set as an alias for `school_record`.

### Enter a single lesson record; special lesson markers

    sr 7 "Properties of quadrilaterals worksheet. Took longer than expected
          because of extensive discussion. hw:(Complete props quads worksheet)"
      # Note:
        - Whitespace is not an issue: words will be chunked into a single
          paragraph anyway.
        - hw: is a keyword, specifying the homework that was set. The data will
          be extracted for a special "homework" report, listing all homework given
          to a class, and will appear in the lesson's notes as "Homework: Complete
          props quads worksheet".  I'll probably tinker with it, allowing things
          like
            hw:(Complete worksheet|Properties of quadrilaterals worksheets)
          The first argument is for the lesson notes; the second is for the
          homework report, giving enough info for when it's taken out of context.

    sr 10 "start:(Non-right-angled trigonometry)"
    # ...weeks later...
    sr 10 "end:(Non-right-angled trigonometry)"
      # These topic markers are used to produce a report on when I started and
      # finished the various topics.

    sr 10 "nc:(Armistice Day assembly)"
      # nc == "no class", with an explanation that will appear in lesson notes,
      # and will prevent this lesson from being counted against the "current"
      # topic.

    sr 10 "spec:(Go over assessment task)"
      # Records a "special" lesson. That is, a lesson that doesn't fit the current
      # sequence, so (like 'nc') it won't count against the "current" topic.

### Enter a note about a student

    sr note 9 "Amy homework incomplete (third time; rubbish duty)"
      # Creates a note about a Year 9 student against today's date.
      # Resovles the name fragment into a real student name from the Year 9 class.
         -> Knowledge of class lists is necessary.
         -> If I have Nicole Beetson and Nicole Tavastok in the class, I can
            use a name fragment like NBee or NTav.
         -> For any operation, failure to resolve a name fragment is an error, not
            a fatal.

### Enter data via text editor

    sr edit
      # Opens an editor in which I can record several classes for today. The
      # program knows what classes I have today and begins with a skeleton like
      # "Day: 2012 Sem2 10B Fri\n\n7: \n\n11: \n\n10: \n", allowing me to fill in
      # the details. Some lessons may already be described. Their data would be
      # shown for context, but commented. When I save the file, new data is
      # committed; comments are ignored. (Try to get the cursor in a useful
      # starting place. Try to detect quit without saving in order to abort.
      # Don't overwrite data without warning; give information and context. Print
      # really simple and concise report after saving the data so the new data can
      # be seen in context.)

    sr edit yesterday     (or sr edit 1)
    sr edit 2
    sr edit 3
    sr edit Mon
    sr edit Mon,Tue
    sr edit 9A-Fri
      # As above, but enter data for, respectively: yesterday, two days ago, three
      # days ago, the most recent Monday, the most recent Monday AND Tuesday, and
      # Friday of Week 9A.

    sr prompt
      # Tell me which lessons are not recorded.

    sr edit prompt
      # Open an editor containing the skeleton for missing lessons, allowing me
      # to enter them.
      # 'missing' seems like a good alternative to or alias for 'prompt'.

A great variety of data can be entered via text editor, including the keywords
start, end, nc, spec, and student notes.

### Undo, move, swap

    sr undo
      # Undo the changes made the last time the command was run. I doubt I'd
      # really bother to implement this, but might as well consider it.

    sr move
      # Move one day's notes to another day, using interactive prompts to get 
      # the information, and warnings if it would cause data to be overwritten.

    sr swap
      # Swap two days' notes, using interactive prompts.

### Reports: day and week

    sr report day    (or 'today')
    sr report week
      # Print all the things that have been recorded today or this week. Nice
      # colour console output. I imagine other time periods can be specified, but
      # a month, for instance, would look a bit long for console output.  I
      # suppose it's important to be able to look at ALL the data, though.

    sr report day -3
    sr report day Mon
    sr report day 9A-Fri
    sr report week -1
    sr report week 6B
    sr report week Sem1-10B
      # Report on days or weeks other than the current one.

### Reports: topics, homework

    sr report topics 10
      # Report on start and end of all Year 10 topics this year, including number
      # of lessons ascribed to each one. Also note dates of unrecorded lessons.

    sr report homework 7
      # Report on all homework assigned to Year 7 for the current topic.

    sr report homework 7 30
    sr report homework 7 5A
    sr report homework 7 5A-
      # Report on all homework assigned to Year 7 for the last 30 lessons, or in
      # Week 5A, or from Week 5A until now.

### Obstancles; past and future lessons

    sr config obstacles
      # Open the obstacles config file in an editor to allow me to record things
      # like exam blocks, excursions, etc. Maybe YAML with entries like:
      #   Term2:
      #     - date: 3 June
      #       year: all
      #       reason: Public holiday (...)
      #     - date: 12B-Wed
      #       year: 7
      #       reason: Geography excursion

    sr report lessons 11
      # Print the lesson notes for the current Year 11 topic (or perhaps the last
      # 10 lessons if topic-based logic is too hard.)

    sr report lessons 11 -1
      # Print the lesson notes for the previous Year 11 topic.

    sr report lessons 11 17
      # Print the lesson notes for the last 17 Year 11 lessons.
      # Think: do these lesson notes include stuff like notes on students?

    sr report lessons 11 future
      # Print the lesson dates for Year 11 for the rest of the term, noting any
      # obstacles.

    sr report lessons 11 future Term3   (or Sem2, or 11A, or Sem2-11A, or ...)
      # As above, but for the specified time period.

### Report: notes about students

    sr report notes 12
      # Print all notes on Year 12 students that have been recorded, grouped by
      # student name and in chronological order.  Default: whole year?

    sr report notes 12 rp1
      # rp1 == "reporting period 1"
      #  -> 'rp1' could be defined in a config file, leaving open the ability to
      #     define other time periods
      #  -> or it could be a hardcoded concept (but with config-defined start and
      #     end dates) thereby allowing "the current reporting period" to be the
      #     default time period for some reports, e.g. 'sr report notes'

    sr report notes 12 Amy Smith
      # Just give me the notes on Amy Smith in Year 12.

### Calendar

    sr config calendar
      # Open the calendar config file in an editor, allowing me to note things
      # like parent-teacher nights, exams I have to write, etc.

    sr calendar
      # Tell me about upcoming calendar events

### A comment about command-line invocation

Unambiguous command abbreviations would be allowed, and the word 'report' could
be omitted so long as there's no clash.  E.g.

    sr cal           # sr calendar
    sr p             # sr prompt
    sr homework 11   # sr report homework 11
    sr report ho     # sr report homework
    sr rep ho        # sr report homework
    sr ho            # Error: ho is not short for any command (?)



## Some thoughts on data storage, organisation, performance

Ideally, storage on disk will be simple.  Plain text files, or yaml files with
simple structures.  The text that is entered should be seen clearly in these
files, and each time the program is run, it needs to process that text and
extract data (homework, notes, ...).  This is inefficient, but in the early
stages of development the flexibility is necessary.  It's possible that a future
version could use a NoSQL database and store higher-level, pre-processed data.
But that's some way off and may never be necessary.  If it hindered performance,
I guess a caching strategy could be implemented whereby processed data (week by
week, semester by semester) was cached and replaced when the underlying data
changed.

In most day-to-day use, only the current day's or week's info will be accessed,
so it should be optimised for that.  It's certainly inappropriate to have to
parse the whole year's data just to enter a single record.  A balance needs to
be struck.  My gut feeling is that a week's data could be the unit.  That is,
one text or YAML file holds a week's data.  Then again, there's no real reason
not to make it a single day.  A week is nothing but an aggregation of days,
anyway.  I cannot imagine a single thing that would be stored against a week
instead of a day.  I envisage a directory structure like:

    Dropbox/AppData/SchoolRecord/
      2012/
        Config/
          calendar.yaml
          class-lists.yaml
          obstacles.yaml
          term-dates.yaml      # (no: this info contained in calendar.yaml)
          timetable.yaml
        Sem1/
          01A/
          02B/
          03A/
            2012-02-13-Mon.yaml
            2012-02-14-Tue.yaml
            ...
          04B/
            2012-02-20-Mon.yaml
            ...
          19A/
        Sem2/
          01A/
          02B/
          ...
          19A/

That would create 38 weekly directories and 190 daily files during the course of
the year.  That seems OK to me.

Using git as a storage mechanism may have some benefits.  Not sure what they'd
be.  (History, obviously: perhaps I could undo changes...)


## Some thoughts on classes

Everything is in the SchoolRecord module, aliased to SR for convenience.

Dirs and Files would give convenient access to the directories and files, both
configuration and data.

LessonRecord encapsulates a record of a single lesson on a single day.  It knows
the date, the year group, the current topic (?) and the description, chunked
into a single line of text. From the description, it can extract tags like 'hw'
and 'spec', which map to objects in their own right.

Homework encapsulates a single piece of homework.  It is associated with a
LessonRecord.  I'm not sure if information about pieces of homework would be
aggregated somehow, or whether they'd be retrieved simply by trawling lessons.
I imagine the latter.

Somehow I need to make a big deal about starting and ending a topic.  StartTopic
and EndTopic classes, or a different way?

Some class needs to be able to take textual data, from the command-line or from
a file, and chunk it into the various LessonRecord and other objects.
DataMuncher?

StudentNotes encapsulates all student notes in the system. StudentNote
encapsulates a single note.

Calendar knows about the school year.  An instance of calendar represents a
single calendar year.  It takes its configuration from calendar.yaml.  That
could be as simple as knowing the start and end date of each term.  It can
determine the weeks (1A, 2B, ...) from that, and can translate between calendar
dates (2012-06-11) and term dates (Sem1-18B-Tue).  It can tell me: what's the
next/previous school day, or iterate over a series of school days.  I suppose a
value object is needed to represent the school day: SchoolDay, with accessors
`term_date` and `calendar_date`, perhaps. SchoolDay.parse(str) would be good: it
can handle parse("3 Jun") or parse("19A-Mon") or parse("Sem2-10B-Thu").

Calendar should know about Staff Days, public holidays, etc.  Things like
excursions, assemblies, etc. are "obstacles".  Obstacles can be postponed or
cancelled.  Public holidays and Staff Days cannot.

Calendar knows that Semester 1 encompasses Terms 1 and 2, and Semester 2
encompasses Terms 3 and 4.  *Reporting periods* are not so easy to define,
though.

I foresee Calendar having nested classes Semester, Term, CalendarEntry (to
define public holidays etc.) and ReportingPeriod.  A single Calendar instance
should contain all the instances of these things that it needs.  The Calendar
class should be able to handle all sorts of useful queries about these things.

There probably needs to be a class like SR::OperatingEnvironment or SR::Context
that contains _the_ calendar, _the_ timetable, _the_ set of obstacles, etc. that
are in use.  That one object can then be passed around or it can be accessible
through a class variable.

Timetable is configured from timetable.yaml and knows when I see each class.  It
probably doesn't need to know what period; only the day.  Does it need to know I
see Year 10 twice on Thursday A, for instance?  We'll see.

Timetable ties in with ClassList.  Each class has a short label, a label, and a
full name, e.g. "10", "10MT1" and "10 Mathematics 1", or something.  I will
probably only use the short label, but it makes sense to store the others.  If
another teacher used this and had two Year 7 classes, for instance, they could
use the short labels to distinguish them, like 7A and 7B.

A ClassList object represents a class and knows the name of all the students and
can resolve a name given a fragment.  I guess that resolution might return a
Student object (class and name).

Obstacle should be a pretty simple class, maybe just a value object with the
date, the class label, and the reason. Although I didn't think so before, the
Calendar object should probably just own an array of Obstacles. It can then
sensibly implement Calendar#lessons("5 May"), etc.

Of course, a very significant class is Report.  But really, it's more of a
namespace.  Each different type of report will have its own class, like
SR::Report::Homework.  This class would take the arguments given, check they're
valid, use the SR::Homework class to get the necessary data, then format a
report.

Some kind of controller may be necessary. This program has a detailed model,
with classes to represent domain objects, backed by a rudimentary filesystem
database. Changes to that model need to be controlled. Perhaps SR::Controller
can handle that. Or do I need a different controller for each part of the model?

To think that through, consider what the app does when run.

    sr note 7 Jess "Homework incomplete"

* App.new.run(["note", "7", "Jess", "Homework incomplete"])
* Command::Note.new(["7", "Jess", "Homework incomplete"])
    * Uses ClassList to resolve the name and produce a 'Student' object
    * Report error to user if resolution impossible.
* note = Note.new(student, "Homework incomplete")
    * This is the model. We create a new note. How does it get persisted?
* NoteController.instance.save(note, date)
    * Something like that?
    * Actually, I think Command::Note functions as the controller.
* Database.save\_note(note, date)
    * That's probably better. Or an instance: @database.save\_note(note, date)


Also need to think about how to handle all the text resulting from an editing
session: `sr -e yesterday`.


## Some thoughts on configuration

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

class-lists.yaml:

    Year7:
      label: '7'
      name: '7MTB2'
      fullname: '7 Mathematics B2'
      students:
        - Jessica Hordern
        - Samantha Barrett
        - Jeanine Foy
        - ...
    Year10:
      label: '10'
      name: '10MT1'
      fullname: '10 Mathematics 1 (accelerated)'
      students:
        - Mikaela Achie
        - Anna-Louise Bayfield
        - Vanessa Chan
        - Karen Chen
        - Ally Cooper
        - Elise Crimmins
        - Milena | De Silva      # note special separator for surname
        - ...


    # Thought: class-lists.yaml could also record dates of entry and exit into
      the class, enabling the program to work out who was in the class on a
      given date.  People who leave the class can't just disappear from the
      list, because then any notes about them would not resolve.
