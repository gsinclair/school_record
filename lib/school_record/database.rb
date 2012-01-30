require 'pathname'
require 'yaml'
require 'pp'

module SchoolRecord
  # A Database stores Note and Lesson objects in an organised way and persists
  # them to disk. It needs to know the base directory where it can read and
  # write its data. The recommended way to create or access a Database object is
  # to use one of the factory methods:
  #   db = Database.test
  #   db = Database.production
  # More of these could be defined, for instance if there were test scenarios
  # requiring different databases.
  #
  class Database
    def Database.dev
      @testdb ||= Database.new( Dirs.dev_database_directory )
    end
    def Database.test
      @testdb ||= Database.new( Dirs.test_database_directory )
    end

    def initialize(directory)
      @files = Files.new(directory)
      @classes = load_class_lists
        # { '7' -> (SchoolClass), '10' -> (SchoolClass), ... }
      @notes = load_notes
        # { '7' -> [Note, Note, ...], ... }
    end

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
      path = @files.timetable_file
      labels = valid_class_labels
      @timetable ||= SR::Timetable.from_yaml(path, labels)
    end

    # Calendar.

    def calendar
      @calendar ||= SR::Calendar.new( @files.calendar_file )
    end

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
  end  # class Database::Files

end  # module SchoolRecord
