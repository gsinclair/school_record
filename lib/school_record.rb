require 'debuglog'
require 'pry'

module SchoolRecord
  # All contents defined in other files.
end

SR = SchoolRecord   # Alias for convenience, used throughout the code.

require 'school_record/util'
require 'school_record/err'
require 'school_record/app'
require 'school_record/report'
require 'school_record/command'
require 'school_record/version'
require 'school_record/domain_objects'
require 'school_record/database'
