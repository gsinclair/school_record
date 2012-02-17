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
    timetalbe.class_labels_only  # -> ['10', '10', '7', '12']

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


