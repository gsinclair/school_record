require 'school_record/command'

module SchoolRecord

  class App
    def initialize
    end

    COMMANDS = {
      note: SR::Command::NoteCmd,
      edit: SR::Command::EditCmd,
      report: SR::Command::ReportCmd,
      config: SR::Command::ConfigCmd
    }

    def class_for_command(command)
      if COMMANDS.key? command.to_sym
        COMMANDS[command.to_sym]
      else
        sr_err :invalid_command, command
      end
    end

    def run(args)
      puts "school-record version #{SchoolRecord::VERSION}"
      command = args.shift
      if command.nil?
        help
      else
        database = Database.dev
        class_for_command(command).new(database).run(args)
      end
    end

    def help
      puts "Help message goes here..."
      puts "Valid commands: #{COMMANDS.keys.join(', ')}"
    end
  end  # class App

end  # module SchoolRecord
