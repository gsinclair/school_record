# Implementing the App skeleton

At the moment, I can run the app and get very basic output

    $ ruby -Ilib bin/school_record
    school-record version 0.0.1.pre

I now want to implement just enough so that I can run the various commands,
like the following, and have it print out the command and the arguments. Of
course, that would be trivial to implement, but I want to put in a bit of
infrastructure, such that every command has its own class.  The commands to
focus on:

    sr note 9 Jess "Incomplete homework"
    sr edit
    sr edit yesterday
    sr edit 9A-Fri
    sr report day
    sr report week 6B
    sr report week Sem1-6B
    sr report topics 10
    sr report homework 7
    sr report homework 7 5A-
    sr report lessons 11
    sr report lessons 11 future
    sr config obstacles
    sr config calendar

This is a modest goal. Once all these are responding correctly (i.e. just
printing their arguments), I can think about processing some of the arguments
and recognising invalid ones.

Commands I'm not interested in at the moment: undo, move, swap. Also, I'm not
yet thinking about things like

    sr 9 "Continued with 8-05; introduced volume."

because that requires infrastructure to recognise "9" as a valid class label.


## Iteration 1

I've implemented enough now so that I get the following:

    $ run
    school-record version 0.0.1.pre
    Help message goes here...
    Valid commands: note, edit, report, config

    $ run note 9 Jess "Incomplete homework"
    school-record version 0.0.1.pre
    Command: note
    Arguments: ["9", "Jess", "Incomplete homework"]

    # Equivalent results for edit, report and config commands.

    $ run foobar
    school-record version 0.0.1.pre
    SchoolRecord error occurred
    Invalid command: ["foobar"]
    /Users/gavin/Projects/school_record/lib/school_record/err.rb:37:in `invalid_command'
    /Users/gavin/Projects/school_record/lib/school_record/err.rb:19:in `sr_err'
    /Users/gavin/Projects/school_record/lib/school_record/app.rb:20:in `class_for_command'
    /Users/gavin/Projects/school_record/lib/school_record/app.rb:30:in `run'
    bin/school_record:7:in `<main>'

OK, so correct commands run correctly, and incorrect ones give a sensible error.

Here's what I did to make it happen:

* SR::App#run(args) selects a command class like SR::Command::NoteCmd, etc.
  and calls #run on an instance of that class.
* Each of the command classes has a basic implementation of #run.

    class SR::Command::NoteCmd
      def run(args)
        puts "Command: note"
        puts "Arguments: #{args.inspect}"
      end
    end

* To handle errors, I have created SR::Err, a module defining the methods
  `sr_err` and `sr_int` for reporting user and internal errors, respectively.
  This module is mixed in to Object so the methods are available everywhere.
  Here are examples of their use:

    sr_err :invalid_command, cmd
      # This indirectly calls SR::ErrorHanding.invalid_command(cmd)

    sr_int "No such error handling method: #{code}"
      # Just raise an SRInternalError

  To sum up, `sr_err` uses error codes so that the message can be carefully
  built away from the code, while `sr_int` just takes a string.


## Iteration 2

There is no Iteration 2. The app skeleton is now in place.  Next step:
implementing enough domain objects and backend store to get a simple command
working.
