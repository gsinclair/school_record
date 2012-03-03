module SchoolRecord

  # SchoolRecord::SRError is used to report a variety of errors in the application.
  class SRError < StandardError
  end

  # SchoolRecord::SRInternalError is used to report errors arising internally,
  # i.e. from bad code.
  class SRInternalError < RuntimeError
  end

  # The SR::Err module defines the method sr_err, which is an interface for
  # error reporting across the whole application, and sr_int, which raises an
  # internal error.
  module Err
    def sr_err(code, *args)
      method_name = code
      if SR::ErrorHandling.respond_to? method_name
        SR::ErrorHandling.send(method_name, *args)
      else
        sr_int "No such error handling method: #{code}"
      end
    rescue SRError => e
      e.set_backtrace caller
      raise e
    end

    def sr_int(msg)
      raise SR::SRInternalError, msg, caller
    end
  end
  ::Object.send :include, SchoolRecord::Err

  # SchoolRecord::ErrorHandling implements the actual error handling.
  module ErrorHandling
    extend self   # All methods are "module" methods.

    def invalid_command *args
      msg = "Invalid command: #{args.first}"
      raise SR::SRError, msg
    end

    def argument_error method_name
      msg = "Argument error: #{method_name}"
      raise SR::SRError, msg
    end

    def multiple_students_match *args
      fragment, label, matches = args.shift(3)
      msg =  "Attempt to match name #{fragment} in class #{label}.\n"
      msg << "Multiple students match: #{matches.join(', ')}"
      raise SR::SRError, msg
    end

    def invalid_name_fragment *args
      fragment = args.shift
      msg = "Cannot resolve name fragment #{fragment}: the format is invalid"
      raise SR::SRError, msg
    end

    def invalid_class_label *args
      label = args.shift
      msg = "Invalid class label: #{label.inspect}"
      raise SR::SRError, msg
    end

    def invalid_object *args
      object, msg = args.shift(2)
      msg = "Invalid #{object.class} object -- #{msg}"
      raise SR::SRError, msg
    end

    def invalid_term_date_string string
      msg = "Invalid date specification: #{string}"
      raise SR::SRError, msg
    end

    def invalid_date_not_this_year string
      msg = "Invalid date (not this year): #{string}"
      raise SR::SRError, msg
    end

    def obstacle_yaml string
      msg = "Invalid Obstacle YAML: #{string.inspect}"
      raise SR::SRError, msg
    end

    def not_a_school_day object
      msg = "Not a school day: #{object.inspect}"
      raise SR::SRError, msg
    end

    def lesson_description_exists ld
      msg =  "Lesson description exists; will not overwrite\n"
      msg << "  Lesson: #{ld.schoolday}; #{ld.class_label}; pd #{ld.period}\n"
      msg << "  Description: #{ld.description}"
      raise SR::SRError, msg
    end
  end
end
