require 'pathname'
require 'yaml'
require 'pp'
require 'data_mapper'

module SchoolRecord
  # A Database stores Note and Lesson objects in an organised way and persists
  # them to disk. It needs to know the base directory where it can read and
  # write its data. The recommended way to create or access a Database object is
  # to use one of the factory methods:
  #   db = Database.dev
  #   db = Database.test
  #   db = Database.production
  # More of these could be defined, for instance if there were test scenarios
  # requiring different databases.
  #
  class Database
    def Database.dev
      debug "Using DEV database"
      @devdb ||= Database.new( Dirs.dev_database_directory )
    end
    def Database.test
      debug "Using TEST database"
      @testdb ||= Database.new( Dirs.test_database_directory )
    end

    def initialize(directory)
      @files = Files.new(directory)
      @classes = load_class_lists
        # { '7' -> (SchoolClass), '10' -> (SchoolClass), ... }
      @notes = load_notes
        # { '7' -> [Note, Note, ...], ... }
      initialize_datamapper
    end
    private :initialize

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

    # Calendar.

    def calendar
      @calendar ||= SR::Calendar.new( @files.calendar_file )
    end

    # Lessons.

    # Return:: [Lesson, Boolean]
    # Lesson is the object that is created or that already existed.  The Boolean
    # value is true if an object was created; false otherwise.  We don't
    # overwrite an existing lesson.
    def store_lesson(date_string, class_label, description)
      sd = calendar.schoolday(date_string)
      sd_str = sd.full_sem_date
      # See if a lesson already exists. We don't want to overwrite it.
      # TODO: take the period into account. Don't want to implement the
      # low-level code for that here. Probably need an intermediate object that
      # groups the lessons for a day, or something.
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

    # database.lessons('today')  # -> Lessons
    def lessons(date_string)
      if sd = calendar.schoolday(date_string)
        lessons_for_day(sd)
      else
        nil   # Maybe raise error.
      end
    end

    def lessons_for_day(sd)
      # TODO: re-implement using DataMapper
      key = sd.date
      if @lessons_by_day[key].nil?
        @lessons_by_day[key] = Lessons.load(@files.lessons_file(sd).read)
      end
      @lessons_by_day[key]
    end
    private :lessons_for_day

    # Sqlite

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

  end  # class Database

  class Database::Dirs
    def self.dev_database_directory
      @dir ||= Pathname.new("etc/dev-db").tap { |p| p.mkpath }
    end
    def self.test_database_directory
      @dir ||= Pathname.new("test/db").tap { |p| p.mkpath }
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
    def sqlite_database_file
      @sqlite ||= @directory.realpath + "lessons_and_notes.db"
    end
  end  # class Database::Files

end  # module SchoolRecord
