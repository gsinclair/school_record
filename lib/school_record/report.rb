
module SchoolRecord
  # SchoolRecord::Report is a namespace to hold reports of various types. E.g.
  # SR::Report::Homework generates a homework report for a given class or
  # student.
  #
  # A Report is a type of Command: you initialize it with a database and
  # optional output stream, and then you run it.
  class Report < SR::Command
    # The various reports are defined below.
  end
end

# --------------------------------------------------------------------------- #

# Generates a report on the notes recorded for a certain student, or for all
# students in a class.
class SR::Report::Notes < SR::Report
  def run(args)
    required_arguments args, 1..2
    class_label, name_fragment = check_arguments(args)
    if name_fragment
      student = @db.resolve_student!(class_label, name_fragment)
      notes = @db.notes(class_label, name_fragment)
      if notes.empty?
        emit "No notes for #{student}"
      else
        emit_student_notes(student, notes)
      end
    else
      notes_per_student = @db.notes(class_label).group_by { |note| note.student }
      students = notes_per_student.keys.sort_by { |s| [s.name.last, s.name.first] }
      students.each do |student|
        notes = notes_per_student[student]
        emit
        emit_student_notes(student, notes)
      end
    end
  end

  def usage_text
    text = %{
      = The 'notes' report requires one or two arguments.  E.g.
      =   school_record report notes 11
      =   school_record report notes 11 JCon
    }.margin
  end

  private
  # Return class label and optional name fragment. Error if args doesn't match
  # this requirement. The number of arguments is checked separately.
  def check_arguments(args)
    class_label, name_fragment = args.shift(2)
    unless @db.valid_class_label? class_label
      sr_err :invalid_class_label, class_label
    end
    [class_label, name_fragment]
  end

  def emit_student_notes(student, notes)
    emit student, :yb
    trace "notes.map { |n| n.date.to_s }", binding if student.name.first == "Isabella"
    notes.sort_by { |n| n.date }.each do |n|
      emit "  #{SR::Util.day_month(n.date)}  #{n.text}"
    end
  end
end  # class SR::Report::Notes

# --------------------------------------------------------------------------- #
