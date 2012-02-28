require 'school_record/command'

module SchoolRecord

  class App
    def initialize(out=nil)
      @out ||= STDOUT
    end

    COMMANDS = {
      note: SR::Command::NoteCmd,
      edit: SR::Command::EditCmd,
      report: SR::Command::ReportCmd,
      config: SR::Command::ConfigCmd,
      enter: SR::Command::DescribeLesson,
    }

    def run(args)
      puts "school-record version #{SchoolRecord::VERSION}"
      command = args.shift
      if command.nil?
        help
      else
        database = Database.dev
        class_labels = database.valid_class_labels
        class_for_command(command, class_labels).new(database).run(command, args)
          # E.g.
          #   NoteCmd.new(database).run("note", ["10", "EKerr", "Too talkative"])
          #   DescribeLesson.new(database).run("7", ["Angles in parallel lines...")
      end
    end

    private
    def class_for_command(command, class_labels)
      if COMMANDS.key? command.to_sym
        COMMANDS[command.to_sym]
      elsif command.in? class_labels
        # The user has run something like
        #   sr 10 yesterday "Sine rule..."
        SR::Command::DescribeLesson
      else
        sr_err :invalid_command, command
      end
    end

    def help
      puts "Help message goes here..."
      puts "Valid commands: #{COMMANDS.keys.join(', ')}"
    end
  end  # class App

end  # module SchoolRecord
