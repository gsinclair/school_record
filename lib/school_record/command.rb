require 'facets/string/indent'
require 'facets/string/margin'

module SchoolRecord
  # Command classes like Note, Edit, etc. are defined in the SR::Command
  # namespace. The generic Command class takes care of storing the Database
  # object that all of them will rely on.
  class Command
    def initialize(db)
      @db = db
    end
    def run(args)
      sr_int "Can't run generic Command object"
    end
    def required_arguments(args, n)
      unless args.size == n
        STDERR.puts usage_text()
        exit!
      end
      args
    end
  end
end

class SR::Command::NoteCmd < SR::Command
  def run(args)
    class_label, name_fragment, text = required_arguments(args, 3)
    student = @db.resolve_student!(class_label, name_fragment)
    puts "Saving note for student: #{student}"
    note = SR::DO::Note.new(Date.today, student, text)
    @db.save_note(note)
    puts "Contents of notes file:"
    puts @db.contents_of_notes_file.indent(4)
  end
  def usage_text
    msg = %{
      - The 'note' command takes three arguments:
      -   * class label
      -   * fragment of student's name
      -   * text for the note (in quotes, so it's one argument)
      - Example:
      -   sr note 9 JCon "Late assignment submission"
    }.margin
  end
end

class SR::Command::EditCmd < SR::Command
  def run(args)
    puts "Command: edit"
    puts "Arguments: #{args.inspect}"
  end
end

class SR::Command::ReportCmd < SR::Command
  def run(args)
    puts "Command: report"
    puts "Arguments: #{args.inspect}"
  end
end

class SR::Command::ConfigCmd < SR::Command
  def run(args)
    puts "Command: config"
    puts "Arguments: #{args.inspect}"
  end
end
