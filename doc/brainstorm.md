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
* Understand the school calendar:
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

    sr -e
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

    sr -e yesterday     (or sr -e 1)
    sr -e 2
    sr -e 3
    sr -e Mon
    sr -e Mon,Tue
    sr -e 9A-Fri
      # As above, but enter data for, respectively: yesterday, two days ago, three
      # days ago, the most recent Monday, the most recent Monday AND Tuesday, and
      # Friday of Week 9A.

    sr prompt
      # Tell me which lessons are not recorded.

    sr -e prompt
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
          term-dates.yaml
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
LessonRecord.

Somehow I need to make a big deal about starting and ending a topic.  StartTopic
and EndTopic classes, or a different way?

Some class needs to be able to take textual data, from the command-line or from
a file, and chunk it into the various LessonRecord and other objects.
DataMuncher?

StudentNote...



