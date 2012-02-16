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
