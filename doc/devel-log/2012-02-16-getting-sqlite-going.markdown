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
