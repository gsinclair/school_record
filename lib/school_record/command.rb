module SchoolRecord
  # Command classes like Note, Edit, etc. are defined in the SR::Command
  # namespace.
  module Command
  end
end

class SR::Command::NoteCmd
  def run(args)
    puts "Command: note"
    puts "Arguments: #{args.inspect}"
  end
end

class SR::Command::EditCmd
  def run(args)
    puts "Command: edit"
    puts "Arguments: #{args.inspect}"
  end
end

class SR::Command::ReportCmd
  def run(args)
    puts "Command: report"
    puts "Arguments: #{args.inspect}"
  end
end

class SR::Command::ConfigCmd
  def run(args)
    puts "Command: config"
    puts "Arguments: #{args.inspect}"
  end
end
