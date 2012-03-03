require 'pathname'
require 'yaml'
require 'pp'
require 'data_mapper'

module SchoolRecord
  # A Database stores Note and LessonDescription objects in an organised way and
  # persists them to disk. It needs to know the base directory where it can read
  # and write its data. The recommended way to create or access a Database
  # object is to use one of the factory methods:
  #   db = Database.dev
  #   db = Database.test
  #   db = Database.production
  # More of these could be defined, for instance if there were test scenarios
  # requiring different databases.
  #
  class Database

    attr_reader :label       # :dev, :test or :prd

    def Database.dev()  Database.init(:dev)  end
    def Database.test() Database.init(:test) end
    def Database.prd()  Database.init(:prd)  end

    # Initialises the database (sqlite and yaml files) for use.
    # Label must be one of :dev, :test, or :prd.
    # Only one database can be loaded. An error will result in trying to load a
    # second one. That's because DataMapper configuration is global.
    # You can "init" the same label many times; it will return a cached object.
    def Database.init(label)
      sr_err :invalid_database, label unless label.in? [:dev, :test, :prd]
      if @database and @database.label != label
        sr_err :database_already_loaded, existing: @database, requested: label
      elsif @database
        debug "Using #{label.to_s.upcase} database (already loaded)"
        return @database
      else
        debug "Loading #{label.to_s.upcase} database"
        @database = Database.new(label, Dirs.database_directory(label))
        nrows = LessonDescription.all.count
        debug "Rows in sqlite database: #{nrows}"
        return @database
      end
    end

    # Returns the current database. This is designed for one case only: for
    # the Datamapper::Property::SchoolDay type to gain access to the calendar.
    # Any other class that needs a Database object should have it passed in.
    # (Maybe there's some way for that to happen with DataMapper too, but I
    # don't think so, because its configuration is global.)
    #
    # If no current database exists, an internal error is raised.
    def Database.current
      if @database
        @database
      else
        sr_int "Trying to access current Database but none is loaded"
      end
    end

    # This method is called only by Database.dev or Database.test or
    # Database.prd, and it's only called once (for each of those), so we should
    # do _all_ setup related to the database here, including setting up
    # datamapper (but that's a global setup...), requiring some of the files
    # (domain_objects.rb or perhaps a subset, database_objects.rb).
    def initialize(label, directory)
      @label = label
      @files = Files.new(directory)
      @classes = load_class_lists
      @calendar = SR::Calendar.new( @files.calendar_file )
      @obstacles = SR::Obstacle.from_yaml(@calendar, @files.obstacles_file.read)
        # { '7' -> (SchoolClass), '10' -> (SchoolClass), ... }
      @notes = load_notes
        # { '7' -> [Note, Note, ...], ... }
      initialize_datamapper(@files.sqlite_database_file)
      clear_sqlite_database if label == :test
      require 'school_record/lesson_description'
      finalize_datamapper
    end
    private :initialize

    def initialize_datamapper(database_path)
      DataMapper::Logger.new($stdout, :debug)
      path = database_path.to_s
      debug "SQLite database path: #{path}"
      DataMapper.setup(:default, "sqlite3://#{path}")
    end
    private :initialize_datamapper

    def clear_sqlite_database
      if @label == :test
        DataMapper.repository(:default).adapter.execute \
          "delete from school_record_lesson_descriptions"
      else
        STDERR.puts "Warn: not clearing #{@label} sqlite database"
      end
    end
    public :clear_sqlite_database

    def finalize_datamapper
      DataMapper.finalize
      DataMapper.auto_upgrade!
    end
    private :finalize_datamapper

    # Notes.

    def load_notes
      notes = Hash.new { |hash, key| hash[key] = [] }
      contents = @files.notes_file.read
      if contents.strip.empty?
        return notes
      else
        data = YAML.load(contents)
        if data.is_a? Hash
          return notes.merge(data)
        else
          msg = "#{@files.notes_file.to_s} contains invalid data.\n"
          msg << contents
          sr_int msg
        end
      end
    end
    private :load_notes
    def save_note(note)
      @notes[note.student.class_label] << note
      @files.notes_file.open('w') do |out|
        out.puts YAML.dump(@notes)
      end
    end
    def notes(class_label, name_fragment=nil)
      notes = @notes[class_label]
      if name_fragment
        students = resolve_student(class_label, name_fragment)
        names = students.map { |s| s.fullname }
        notes = notes.select { |note|
          note.student.fullname.in? names
        }
      end
      notes
    end
    def contents_of_notes_file
      @files.notes_file.read
    end

    # Class lists.

    def load_class_lists
      data = YAML.load(@files.class_lists_file.read)
        # See file class-lists.yaml for the format of the data.
      result = {}
      data.each do |key, hash|
        label, full_label, full_name, students =
          hash.values_at('label', 'full_label', 'full_name', 'students')
        students = students.map { |str|
          last, first = str.split(', ')
          SR::DO::Name.new(first.strip, last.strip)
        }
        result[label] = SR::DO::SchoolClass.new(label, full_label, full_name, students)
      end
      result
    end
    private :load_class_lists
    def valid_class_label?(label)
      @classes.key? label
    end
    def valid_class_labels
      @classes.keys.dup
    end
    def resolve_student(class_label, name_fragment)
      @classes[class_label].resolve(name_fragment)
    end
    def resolve_student!(class_label, name_fragment)
      @classes[class_label].resolve!(name_fragment)
    end

    # Timetable.

    def timetable
      @timetable ||= (
        path = @files.timetable_file
        labels = valid_class_labels
        SR::Timetable.from_yaml(path, labels)
      )
    end
    # Returns the classes for a given day, or nil if that day isn't a school
    # day.  For example:
    #   @db.classes('yesterday')    # -> ['7', '9', '12', '10']
    #   @db.classes('Saturday')     # -> nil
    #   @db.classes('25 Apr')       # -> nil  (Anzac Day)
    # This method takes account of non-school days, because Calendar#schoolday
    # does, but it does not take account of obstacles (e.g. exams).
    def classes(date_string)
      if sd = calendar.schoolday(date_string)
        timetable.classes(sd)
      else
        nil
      end
    end

    # NOTE: This is a stop-gap method to help tests pass that were breaking
    # because of changes being introduced to the code. When there is a better,
    # program-wide conception of "lessons" (class_label and period), I can
    # hopefully remove this method and maybe even the one above, as I will be
    # implementing Database#timetabled_lessons.
    #
    # If Database#classes is to remain, then it should probably be called
    # Database#lessons instead, returning an array of Lesson objects.
    def class_labels_only(date_string)
      if sd = calendar.schoolday(date_string)
        timetable.class_labels_only(sd)
      else
        nil
      end
    end

    # Calendar.

    def calendar
      @calendar
    end

    def schoolday(date_string)
      @calendar.schoolday(date_string)
    end

    def schoolday!(date_string)
      if (sd = schoolday(date_string)).nil?
        err :not_a_school_day, date_string
      else
        sd
      end
    end

    # Returns array of TimetabledLesson objects representing the lessons that
    # are _supposed_ to happen on the given day. If there is an obstacle, the
    # TimetabledLesson object will know about it.
    #
    # If a class_label is provided, only lessons matching that label will be
    # returned.
    def timetabled_lessons(schoolday, class_label=nil)
      ttls = timetable.lessons(schoolday.day_of_cycle).map { |lesson|
        obstacle = @obstacles.find { |o| o.match?(schoolday, lesson) }
        SR::TimetabledLesson.new(schoolday, lesson, obstacle)
      }
      if class_label
        ttls.select { |tl| tl.class_label == class_label }
      else
        ttls
      end
    end

    # Lessons (as in LessonDescriptions).

    # Return:: [LessonDescription, Boolean]
    # LessonDescription is the object that is created or that already existed.
    # The Boolean value is true if an object was created; false otherwise.  We
    # don't overwrite an existing lesson.
    def store_lesson(date_string, class_label, description)
      sd = calendar.schoolday(date_string)
      sd_str = sd.full_sem_date
      # See if a lesson already exists. We don't want to overwrite it.
      # TODO: take the period into account. Don't want to implement the
      # low-level code for that here. Probably need an intermediate object that
      # groups the lessons for a day, or something.
      lesson = LessonDescription.first(schoolday: sd_str, class_label: class_label)
      debug "Search for existing lesson revealed: #{lesson}"
      if lesson
        return [lesson, false]
      else
        lesson = LessonDescription.create(schoolday: sd_str,
                                          class_label: class_label,
                                          description: description)
        return [lesson, true]
      end
    end

    # database.lessons('today')  # -> [ LessonDescription ]
    # NOTE: This method will almost certainly be replaced by timetabled_lessons.
    def lessons(date_string)
      if sd = calendar.schoolday(date_string)
        # lessons_for_day(sd)
        # NOTE: above line commented out because lessons_for_day assumed the
        # existence of class Lessons, which was based on the YAML approach.
      else
        nil   # Maybe raise error.
      end
    end

  end  # class Database

  class Database::Dirs
    def self.database_directory(label)
      case label
      when :dev
        Pathname.new("etc/dev-db").tap { |p| p.mkpath }
      when :test
        Pathname.new("test/db").tap { |p| p.mkpath }
      when :prd
        sr_int "Production database directory not yet defined"
      end
    end
  end  # class Database::Dirs

  class Database::Files
    def initialize(directory)
      @directory = Pathname.new(directory)
    end
    def notes_file
      @nf ||= @directory + "notes.yaml"
    end
    def class_lists_file
      @clf ||= @directory + "Config/class-lists.yaml"
    end
    def timetable_file
      @tf ||= @directory + "Config/timetable.yaml"
    end
    def calendar_file
      @cf ||= @directory + "Config/calendar.yaml"
    end
    def obstacles_file
      @of ||= @directory + "Config/obstacles.yaml"
    end
    def sqlite_database_file
      @sqlite ||= @directory.realpath + "lessons_and_notes.db"
    end
  end  # class Database::Files

end  # module SchoolRecord
