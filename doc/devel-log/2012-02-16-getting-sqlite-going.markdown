# Getting SQLite going

It was a big struggle caused by a stupidly simple PEBCAK error, but I've now got
SQLite and DataMapper going, and I'm happy with it.  This currently works:

    sr enter 10 "fklajfa;lfja;lsdfjka"
    # -> saves record in dev database etc/dev-db/lessons_and_notes.db
    sr enter 10 "fakfj;alkfjalfjal;kdfj"
    # -> does not overwrite existing record

Two problems immediately present themselves:

* There is no way to save a note for a day other than today. (That will be
  easily rectified.)
* Only one record can be added per class per day.
    * There is no checking of the timetable at the moment.
    * If I have a double period, I need two records.

Here is the relevant code.

    class Database:

      # Return:: [Lesson, Boolean]
      # Lesson is the object that is created or that already existed.  The Boolean
      # value is true if an object was created; false otherwise.  We don't
      # overwrite an existing lesson.
      def store_lesson(date_string, class_label, description)
        sd = calendar.schoolday(date_string)
        sd_str = sd.full_sem_date
        # See if a lesson already exists. We don't want to overwrite it.
        lesson = Lesson.first(schoolday: sd_str, class_label: class_label)
        debug "Search for existing lesson revealed: #{lesson}"
        if lesson
          return [lesson, false]
        else
          lesson = Lesson.create(schoolday: sd_str, class_label: class_label,
                                 description: description)
          return [lesson, true]
        end
      end

      def initialize_datamapper
        sr_err :datamapper_already_initialized if @datamapper_initialized
        DataMapper::Logger.new($stdout, :debug)
        path = @files.sqlite_database_file.to_s
        debug "Database path: #{path}"
        DataMapper.setup(:default, "sqlite3://#{path}")
        require 'school_record/lesson'
        DataMapper.finalize
        DataMapper.auto_upgrade!
        debug "There are #{Lesson.all.count} lessons in the database."
        debug Lesson.all.map { |l| l.inspect }.join("\n")
        @datamapper_initialized = true
      end
      private :initialize_datamapper

    class SchoolDay:
      def full_sem_date()  sem_date(:semester)  end
      def short_sem_date() sem_date(false)      end

    module SchoolRecord
      # Represents a single lesson.
      class Lesson
        include DataMapper::Resource
        property :id,          Serial
        property :schoolday,   String     # "Sem1 3A Fri"
        property :class_label, String     # "10"
        property :description, Text       # "Completed yesterday's worksheet. hw:(4-07)"
      end
    end

    class EnterLesson:
      def run(args)
        class_label, description = required_arguments(args, 2)
        date_string = 'today'           # Maybe have a way to specify this.
        # Basically, we hand this to Database. It can check whether this lesson has
        # already been defined, and save it if not.
        lesson, stored = @db.store_lesson(date_string, class_label, description)
        if stored
          emit "Saving lesson record for class #{class_label}"
        else
          emit "A lesson for class #{class_label} already exists; not overwriting."
          emit "Existing description: #{lesson.description}"
        end
      end

Committing the code now so I have a fresh start for further work on the SQLite
side of things.

## Getting period information into the timetable

To address the timetable side of things, I'm starting to think the timetable
needs to include information about the period for each lesson. I kinda can't be
bothered implementing that, but it's starting to look inevitable. Each lesson
object would know what period it is, and that would make it easy to store
doubles.

At the moment Config/timetable.yaml looks like this:

    WeekA:
      Mon: "10,11,7,12"
      Tue: "10,12,11,7"
      Wed: "11,12,7,10"
      ...

With period information it could be

    WeekA:
      Mon: "10:a,11:1,7:4,12:5"
      Tue: "10:2,12:3,11:4,7:5"
      Wed: "11:1,12:2,7:4,10:5"
      ...

or

    WeekA:
      Mon: "10,11,_,_,7,12,_"
      Tue: "_,_,10,12,11,7,_"
      Wed: "_11,12,_,7,10,_"
      ...

I prefer the latter. The first period in the list is "alpha". Maybe that can
just be the number zero in the database.

What about the Timetable object?  The current API is simply

    timetable.classes(sd)  # -> ['10', '10', '7', '12']

I don't see a need for that method to change, but I guess we could have

    timetable.lessons(sd)  # -> [ ['10',0], ['10',1], ['7',2], ['12',5] ]

Perhaps there would be no need for #classes anymore since any code that works
with the SQLite database would need to know what period things were on.  The
method name "lessons" may be confusing, suggesting that it returns an array of
Lesson objects.  `classes_and_periods`?  Or simply redefine `classes`?

It appears that the `classes` method is not actually used at the moment! So I'll
probably redefine it, and implement `class_labels_only` just in case I want that
functionality.  Reimplementing `classes` will mean changing the test files as
well, of course.

Done. I now have

    timetable.classes            # -> [ ['10',0], ['10',1], ['7',2], ['12',5] ]
    timetable.class_labels_only  # -> ['10', '10', '7', '12']

There is a new nested class behind the scenes, Day, that encapsulates timetable
information about a single day.  It's not exposed, though: its methods just
return the arrays above. There is potential to get information like "what is on
period 6", but I'll wait for a need before implementing it.

The test code is updated too.  It (still) doesn't test that an erroneous config
file raises an error, but that's not too important.

Committing.

## Getting period data into Lesson objects

Adding the property is easy.

    class Lesson
      include DataMapper::Resource
      property :id,          Serial
      property :schoolday,   String     # "Sem1 3A Fri"
      property :class_label, String     # "10"
      property :period,      Integer    # (0..6), 0 being before school
      property :description, Text       # "Completed yesterday's worksheet. hw:(4-07)"
    end

Now what? Here is `Database#store_lesson`:

    # Return:: [Lesson, Boolean]
    # Lesson is the object that is created or that already existed.  The Boolean
    # value is true if an object was created; false otherwise.  We don't
    # overwrite an existing lesson.
    def store_lesson(date_string, class_label, description)
      sd = calendar.schoolday(date_string)
      sd_str = sd.full_sem_date
      # See if a lesson already exists. We don't want to overwrite it.
      lesson = Lesson.first(schoolday: sd_str, class_label: class_label)
      debug "Search for existing lesson revealed: #{lesson}"
      if lesson
        return [lesson, false]
      else
        lesson = Lesson.create(schoolday: sd_str, class_label: class_label,
                               description: description)
        return [lesson, true]
      end
    end

The code that says `Lesson.first` is the heart of the problem. We really need a
new object -- LessonsForADay or something -- that takes care of finding a blank
lesson for a given timetabled day (taking account of public holidays,
excursions, etc.). I just wish I could think of a good name. Anyway, here is
some possible code.

    class Database:
      def store_lesson(date_string, class_label, description, period=nil)
        lfad = LessonsForADay.new(self, date_string)
        lfad.store_lesson(class_label, period, description)
          # returns [Lesson, Boolean]
      end

    class LessonsForADay:
      def initialize(database, date_string)
        @database  = database
        @schoolday = database.schoolday(date_string)
        @classes   = database.classes(@schoolday)
                        # -> [ ['10',1], ['7',2], ['12',5] ]
        @obstacles = database.obstacles(@schoolday)  # not sure of this API
                        # -> [ Obstacle, ... ]
      end

      # If period is nil, the first available period is taken.
      def store_lesson(class_label, period, description)
        matching_classes = @classes.select { |cl, pd| cl == class_label }
          # -> [ ['10',0], ['11',1] ]
        matching_classes = matching_classes.reject { |pd, cl| ... }
      end

I don't like the style of code I'm writing here. It doesn't feel like the right
design. I especially don't like the arrays that are passed around to include a
class label and a period number. This should be an object, and I think I've
found the right one:

    class TimetabledLesson
      schoolday
      class_label
      period
      obstacle?
      obstacle

This provides information about, well, a timetabled lesson.  The "Lesson" class
should probably change its name to "LessonDescription", because that's what it
contains.

    sd = database.schoolday('Fri 3A')
    database.timetabled_lessons(sd)
      # -> [ TimetabledLesson, ... ]         (all classes for that day)
    database.timetabled_lessons(sd, '12')
      # -> [ TimetabledLesson, ... ]         (all Year 12 classes for that day)

The TimetabledLesson objects returned have obstacle information built into them.
That should make it easier to store a lesson on a given day, and hopefully will
mean I _don't_ need a class just for handling a day's worth of lessons. The
array of TimetabledLesson objects will have enough smarts.

I guess the Database class could maintain a hash of the LessonDescription
corresponding to each TimetabledLesson. There may be a use for that.

I feel like I'm finally making conceptual progress now. Here's what has to
happen:

* Design, implement and test obstacles.
* Implement and test TimetabledLesson (probably not much to test).
* Implement and test Database#timetabled\_lessons (this is where the real tests
  will be).
* Implement Database#store\_lesson.

At this point, I'll need to work out how I'm going to test sqlite-related stuff,
like storing lessons.

Another thought: it's possible I will need a TimetabledLessons class to
encapsulate a group of them, and which provides convenience methods that iterate
over the group. But the group need not necessarily be a day's worth of lessons.
I'll avoid this class if I can, though.

(This is all 17 Feb, by the way.)

Code committed to give me a fresh base. The only code actually committed was
the 'period' property in the Lesson class :)  But the notes in this file were an
important part of that commit as well.

## Obstacles

These have been a conceptual part of the system since the initial brainstorm,
but no design or implementation has been done since then. These can be pretty
dumb objects that simply reflect the YAML file containing them. The Database
object can organise them (probably just an array; maybe a hash) and sort the
information into TimetabledLesson objects.

    obstacles.yaml:

        Sem1:
          - date: 3 June
            classes: 7, 10
            reason: Moderator's assembly
          - date: 12B-Wed
            class: 7
            reason: Geography excursion
          - dates: ["9A-Mon", "9A-Thu"]
            class: 7
            reason: Exams
          - date: 3A-Mon
            class: 11(4)
            reason: Maths assembly
        Sem2:
          - ...

This is the 'ap' output for the Sem1 part of the above YAML snippet.

    {
      "Sem1" => [
        [0] {
              "date" => "3 June",
           "classes" => "7, 10",
            "reason" => "Moderator's assembly"
        },
        [1] {
              "date" => "12B-Wed",
             "class" => 7,
            "reason" => "Geography excursion"
        },
        [2] {
             "dates" => [
                [0] "9A-Mon",
                [1] "9A-Thu"
            ],
             "class" => 7,
            "reason" => "Exams"
        },
        [3] {
              "date" => "3A-Mon",
             "class" => "11(4)",
            "reason" => "Maths assembly"
        }
      ]
    }

From that data, I can see an object like this:

    class Obstacle
      dates()
      classes()
      period()     # will be nil most of the time
      reason()
      match?(schoolday, class_label)

That "match?" method will be key in determining whether an obstruction affects a
given class on a given day.

The object can be initialized with a hash, so it can interpret the "date" or
"dates" keys, etc. So the guts of this class are the methods initialize() and
match?(schoolday, class\_label).

A period can be specified in the YAML file, to handle those cases where a class
has more than one lesson in a day, and only one of them is obstructed.  If no
period is specified, then _all_ classes with the given class label are included
in the obstacle. The period is demonstrated in this fragment:

          - date: 3A-Mon
            class: 11(4)
            reason: Maths assembly

It remains to be seen how "match?" works with specified periods. Time will tell.

...

After some considerable work writing tests for Obstacle and then implementing
it, including classes SR::Obstacle and SR::ObstacleCreator, I've hit a painful
realisation:

* Calendar#schoolday has a bias towards interpreting dates in the _past_. If you
  type "Fri" at the command-line when wanting to enter lesson notes, you
  obviously mean _last_ Friday.
* Obstacles, however, can naturally be specified in the _future_.  So if an
  obstacle is dated "5 June" and it's currently 18 Feb 2012, then Chronic will
  return 5-Jun-2011. It's just doing what it's told with the `context: :past`
  option.
* Some ways to resolve this:
    * Always massage the generated date to be this year. (Hack.)
    * Apply the `:context` option sparingly, only when it is detected that the
      date string is something simple like "Fri".
        * It would be nice if Chronic had a context "this year" instead of just
          "past" and "future"...
    * Implement a class DateString that does some rudimentary parsing and can
      answer questions about the type of content: does it have a day, a week, a
      semester, a month, ...?

I'm pretty sure I will go with the DateString class, and even change the
implementation of Calendar#schoolday to use it. Some code could then be:

    ds = DateString.new(string)
    if ds.contains_only?(:wday, :week)
      string << " Sem#{semester}"
    end
    if ds.contains_only?(:mday, :month)
      string << " #{Date.today.year}"
    end
    @calendar.schoolday(string)

[Aside] I just noticed that Note is in DomainObjects but Lesson is not, even
though they are both clearly domain objects and will both be stored in the
sqlite database.  I think I should move Lesson to DomainObjects and move the
sqlite setup away from Database and into lib/school\_record.rb.  (Not in this
commit.)

OK, DateString is implemented and tested.  It's not time to commit, though,
because Obstacle is in mid-implementation.  This testing extract demonstrates
the DateString API:

    ds = SR::DateString.new("Mon-13A")
    F ds.iso_date?
    T ds.contains?(:wday)
    T ds.contains?(:sem_week)
    T ds.contains?(:wday, :sem_week)
    T ds.contains_only?(:wday, :sem_week)
    F ds.contains?(:year)
    T ds.semester_style?
    F ds.day_month_style?
    Eq ds.to_s, "Mon-13A"

Back to obstacles.  I used DateString to solve that problem of dates being
inappropriately in the past.  Nice and elegant.  The following tests now pass:

    D "First one: 5 Jun" do
      ob = @obstacles.shift
      sd_5_jun = @cal.schoolday('2012-06-05')
      sd_6_jun = @cal.schoolday('2012-06-06')
      Eq ob.schooldays.first, sd_5_jun
      Eq ob.class_labels, ['7', '10']
      Eq ob.reason, "Moderator's assembly"
      Eq ob.period, nil

But the next one fails:

      T  ob.match?(sd_5_jun, '7')

I'm leaving it here and going to bed. This is just to remind myself where to
pick up.

_(Sun 19 Feb)_

Obstacle matching is now done. Along the way I made SchoolDay objects
Comparable (by delegating to their date).

Last problem: obstacles that concern specific periods. I've deferred thinking
about this problem until necessary, and now it's necessary. Obstacle objects can
currently have a period, like

    - date: 3A-Mon
      class: 11(4)
      reason: Maths assembly

but it's not implemented yet. In fact the current code simply assigns '11(4)' to
the class in that case.

After some consideration, I've decided it's time to introduce a value object to
look after these things: the Lesson.

## Lesson, revisited

My current Lesson class is more properly named LessonDescription, as mentioned
earlier. It is now time to make that change and introduce a value object called
Lesson, which simply encapsulates a certain class having a lesson at a certain
time (period) of a certain day.

    class Lesson
      class_label
      period
      schoolday      # may be nil (?)

I already have something like this in TimetabledLesson, which looks like

    class TimetabledLesson
      schoolday      # may not be nil
      class_label
      period
      obstacle?
      obstacle

Perhaps it is not necessary to have both of these, but I don't see it yet.
TimetabledLesson has a particular purpose: to know which lessons are supposed to
be on a particular day and know if they are obstructed by an assembly, etc. They
are concrete objects that will match up with a LessonDescription that resides,
or is soon to reside, in the database. (In fact, "description" could even be a
method on TimetabledLesson, not that I'm thinking that at the moment.)

Lesson, on the other hand, is just a value object for passing to methods, to
specify a putative lesson. It may not even need a "schoolday" property; it's the
confluence of class\_label and period that is most needed.

So the plan is:

* Change Lesson to LessonDescription throughout the code.
* Introduce Lesson, where schoolday may be nil.
* Use this object wherever possible, and make all the relevant code
  period-aware.
* See what uses it has. Maybe I don't need "schoolday" at all (it can be a
  separate parameter when needed); maybe I can use TimetabledLesson some of the
  time.

Keep in mind: TimetabledLesson is important for the operation of the
application. Lesson is just a value object that helps to generate the
TimetabledLesson objects.

Committing code (not much) and this file (much) to create a fresh conceptual
space for the above plan to be implemented.
