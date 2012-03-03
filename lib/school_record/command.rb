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
    def run(command, args)
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
  def run(command, args)
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

class SR::Command::DescribeLesson < SR::Command
  # E.g. The following two are equivalent and must be handled carefully.
  #   run("enter", ["10", "yesterday", "Sine rule..."])
  #   run("10", ["yesterday", "Sine rule..."])
  def run(command, args)
    debug "*** DescribeLesson#run ***"
    class_label = (command == "enter" ? args.shift : command)
    err :invalid_class_label unless @db.valid_class_label?(class_label)
    args = required_arguments(args, 1..2)
    description, date_string = args.pop, args.pop

    sd = @db.schoolday!(date_string || 'today')
    emit "Retrieving lessons for #{sd.full_sem_date}"
    ttls = @db.timetabled_lessons(sd, class_label)

    # We now have all the timetabled lessons for this class on this day.
    # There could be obstacles, though. Report to the user if there are. Select
    # the first non-obstacled, non-described lesson for saving the description.
    if ttls.empty?
      emit "  - no lessons for #{class_label} on this date"
      exit!
    end

    lesson = ttls.find { |l| l.obstacle.nil? and l.description.nil? }
    if lesson
      lesson.store_description(description)
      emit "Stored description in period #{lesson.period}"
    else
      # Report to the user.
      pds = ttls.map { |l| l.period }.join(', ')
      emit "On #{sd.sem_date}, class #{class_label} has lessons in periods: #{pds}"
      ttls.each do |l|
        if l.obstacle?
          emit "- can't store in pd #{l.period}: #{l.obstacle.reason}"
        elsif l.description
          emit "- can't store in pd #{l.period}: already described"
          emit l.description.indent(8)
        end
      end
    end
  end

  def usage_text
    msg = %{
      - The 'enter' command takes two or three arguments:
      -   * class label
      -   * date string (optional; use quotes if necessary)
      -   * string describing the lesson (use quotes)
      - Example:
      -   sr enter 10 "Cosine rule. hw:(7-06 Q1-4)"
      -   sr enter 10 yesterday "Sine rule"
      -   sr enter 12 'Fri 3A' "Definite integrals hw:(3.4)"
      - Example (shortcut):
      -   sr 11 "Line of best fit"
      -   sr 11 Fri "Equations with fractions"
      -
      - You can't specify the period; this is meant to be simple.
      - Use the 'edit' command for more complex lesson descriptions.
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

  def run(command, args)
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
  def run(command, args)
    puts "Command: edit"
    puts "Arguments: #{args.inspect}"
  end
end

# --------------------------------------------------------------------------- #

class SR::Command::ConfigCmd < SR::Command
  def run(command, args)
    puts "Command: config"
    puts "Arguments: #{args.inspect}"
  end
end
