require 'facets/string/indent'
require 'facets/string/margin'

module SchoolRecord
  # Command classes like Note, Edit, etc. are defined in the SR::Command
  # namespace. The generic Command class takes care of storing the Database
  # object that all of them will rely on.
  class Command
    def initialize(db, out=nil)
      @db = db
      @out = out || STDOUT
    end
    def run(args)
      sr_int "Implement #run in subclass"
    end
    # required_arguments args, 3
    # required_arguments args, 1..2
    def required_arguments(args, n)
      n = (n..n) if Fixnum === n
      unless n.include? args.size
        STDERR.puts usage_text()
        exit!
      end
      args
    end
    def usage_text
      sr_int "Implement #usage_text in subclass"
    end
    # Emits a line of text to the output stream, optionally colouring it.
    #   emit "foo"
    #   emit "foo", :rb       # red, bold
    def emit(str="", col_format_code=nil)
      str = str.to_s
      if col_format_code
        str = Col(str).fmt(col_format_code)
      end
      @out.puts str
    end
  end
end

# --------------------------------------------------------------------------- #

class SR::Command::NoteCmd < SR::Command
  def run(args)
    class_label, name_fragment, text = required_arguments(args, 3)
    student = @db.resolve_student!(class_label, name_fragment)
    emit "Saving note for student: #{student}"
    note = SR::DO::Note.new(Date.today, student, text)
    @db.save_note(note)
    emit "Contents of notes file:"
    emit @db.contents_of_notes_file.indent(4)
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

# --------------------------------------------------------------------------- #

class SR::Command::EnterLesson < SR::Command
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
  def usage_text
    msg = %{
      - The 'enter' command takes two arguments:
      -   * class label
      -   * string describing the lesson (use quotes)
      - Example:
      -   sr enter 10 "Cosine rule. hw:(7-06 Q1-4)"
    }.margin
  end
end

# --------------------------------------------------------------------------- #

require 'school_record/report'

class SR::Command::ReportCmd < SR::Command

  REPORTS = {
    notes: SR::Report::Notes,
#   lessons: SR::Report::Lessons,
#   day: SR::Report::Day,
#   week: SR::Report::Week,
#   homework: SR::Report::Homework,
  }

  def run(args)
    report_type = args.shift
    if report_type.nil?
      help
    else
      class_for_report(report_type).new(@db, @out).run(args)
    end
  end

  private
  def class_for_report(report_type)
    report_type = report_type.to_sym
    if REPORTS.key?(report_type)
      REPORTS[report_type]
    else
      sr_err :invalid_report_type, report_type
    end
  end
end

# --------------------------------------------------------------------------- #

class SR::Command::EditCmd < SR::Command
  def run(args)
    puts "Command: edit"
    puts "Arguments: #{args.inspect}"
  end
end

# --------------------------------------------------------------------------- #

class SR::Command::ConfigCmd < SR::Command
  def run(args)
    puts "Command: config"
    puts "Arguments: #{args.inspect}"
  end
end
