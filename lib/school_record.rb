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
require 'school_record/timetable'
require 'school_record/calendar'
require 'school_record/database'
# We don't require 'school_record/lesson', because that requires a database to
# be selected (dev, test, prd). The Database class loads 'lesson' at the
# appropriate time.
