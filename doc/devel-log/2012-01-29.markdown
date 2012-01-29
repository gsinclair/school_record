# Report on notes

The last thing I did was implement the "note" command.

    sr note 9 EmmaD "Solved challenging problem"

That required a lot of work: SchoolClass, Database.  I'm not sure what to bite
off next, but think I'll try a report on notes.

    sr report notes 11           # whole class
    sr report notes 11 JBla      # just Jessica Blake
    sr report notes 11 rp1       # reporting period 1

That last one isn't going to get done now, and probably not even soon.  But the
other two are achievable.  I'm going to keep the output basic at this stage.  In
designing the Report::Notes class, it's important to keep testability in mind,
so I'm not entirely dependent on the command-line to test it.

Example output:

    $ sr report notes 11

    Abigail Blake
       2 Feb  Incomplete homework
       9 Mar  Good assignment submission
      11 Mar  Argumentative

    Jenny Garvin
       1 Feb  Uncooperative in completing work
      21 Feb  Well behaved

    ...

    $ sr report notes 11 JG

    Jenny Garvin
       1 Feb  Uncooperative in completing work
      21 Feb  Well behaved

So I need my first Report class, SR::Report::Notes.  At the moment, the command
looks like this:

    class SR::Command::ReportCmd < SR::Command
      def run(args)
        puts "Command: report"
        puts "Arguments: #{args.inspect}"
      end
    end

To run the report command, we need to work out what kind of report it is. The
first argument ("notes") determines that, so we will create the appropriate
class based on that argument, just like App#run does it.

I've put some skeleton in place. Notice the 'out' parameter, meaning you can
have a report generated into a StringIO for testing.  This code is _very_
similar to the Command class.
 
    # lib/school_record/command.rb

    class SR::Command::ReportCmd < SR::Command
      REPORTS = {
        notes: SR::Report::Notes,
        lessons: SR::Report::Lessons,
        day: SR::Report::Day,
        week: SR::Report::Week,
        homework: SR::Report::Homework,
      }

      def initialize(db, out=nil)
        @out = out || STDOUT
      end

      def run(args)
        report_type = args.shift
        if report_type.nil?
          help
        else
          class_for_report(report_type).new(@out).run(args)
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

    # lib/school_record/report.rb

    module SchoolRecord
      # SchoolRecord::Report is a namespace to hold reports of various types. E.g.
      # SR::Report::Homework generates a homework report for a given class or
      # student.
      class Report
        def initialize(db, out=nil)
          @db  = db
          @out = out || STDOUT
        end
        # Emits a line of report.
        #   emit "foo"
        #   emit "foo", :rb       # red, bold
        def emit(str, col_format_code=nil)
          if col_format_code
            str = Col(str).fmt(col_format_code)
          end
          @out.puts str
        end
        # The various reports are defined below.
      end
    end

    # Generates a report on the notes recorded for a certain student, or for all
    # students in a class.
    class SR::Report::Notes < SR::Report
      def run(args)
        emit "Hi", :yb
      end
    end

When I run `run report notes`, it emits "Hi" in yellow bold, exactly as written.
Now to implement SR::Report::Notes#run properly.

What does a notes report do?

* Checks that the arguments are correct.  Must be something like ['9'] or
  ['11', 'JaneD'].
* Asks the database for all notes for a given class, or all notes for the given
  student (the Database class handles both cases).
    * If it's for the whole class, we would group it into students. (?)
* Emits a series of lines to the output to communicate the results.

Pretty simple, really.

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
          @db.notes(class_label).group_by { |n| n.student }.each do |student, notes|
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
        notes.sort_by { |n| n.date }.each do |n|
          emit "  #{n.date}  #{n.text}"
        end
      end
    end  # class SR::Report::Notes

And it works:

    $ run report notes 9

    Mikaela Achie (9)
      2012-01-28  Equipment

    Anna Kirkby (9)
      2012-01-28  Equipment


    $ run report notes 9 AK
    Anna Kirkby (9)
      2012-01-28  Equipment


The date format is not nice, though.  I want "28 Jan", not "2012-01-28".  In
future I will probably want "28 Jan" _and_ "2B-Wed", but that's in future...

I introduced `SR::Util.day_month(date)` rather than fiddle around with date
format strings everywhere.

## Conclusion

That reporting code was easy to write, and I ended up improving some other code
as well:

* Report is now a subclass of Command, so all reports get their database and
  output stream initialization for free.  Reports can use required\_arguments
  and implement usage\_text to print a help message if the wrong number of
  arguments are given.
* The 'emit' method moved to Command, so all commands can take advantage of it.
  The 'note' command now uses emit instead of puts.

Just gotta write some tests and it's time to commit.

The tests exposed an error: a report on a whole class was not sorting the
students in alphabetical order.

Another error exposed. Students were not being grouped in a class. Needed to
implement eql? and hash in my value objects properly.
