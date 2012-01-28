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
        SR::ErrorHandling.send(method_name, args)
      else
        sr_int "No such error handling method: #{code}"
      end
    end

    def sr_int(msg)
      raise SR::SRInternalError, msg
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

  end
end
