
require 'dm-core'
require 'dm-types'

module DataMapper
  class Property
    class SchoolDay < DataMapper::Property::String

      def custom?
        true
      end

      def load(value)
        # Take a string from the database and load it. We need a calendar!
        val = case value
        when ::String then calendar.schoolday(value)
        when ::SR::DO::SchoolDay then value
        else
          sr_int error_message(:load, value)
        end
        val
      end

      def dump(value)
        # Store a SchoolDay value into the database as a string.
        #trace :caller, binding
        val = case value
        when SR::DO::SchoolDay
          sd = value
          "Sem#{sd.semester} #{sd.weekstr} #{sd.day}"
        when ::String
          value
        else
          sr_int error_message(:dump, value)
        end
        val
      end

      def typecast(value)
        # I don't know what this is supposed to do -- that is, when and why it
        # is called -- but I am aping the behaviour of the Regexp custom type,
        # which, like this one, stores as a String and loads as something else.
        load(value)
      end

      private

      def calendar
        @calendar ||= SR::Database.current.calendar
      end

      def error_message(method, value)
        case method
        when :load
          "Trying to load schoolday from database; " \
            "it should be a String or SchoolDay but it's a #{value.class}."
        when :dump
          "Trying to save schoolday value to database, but it's a " \
            "#{value.class} instead of a SchoolDay or String."
        end
      end

    end  # class SchoolDay
  end  # class Property
end  # class DataMapper

# --------------------------------------------------------------------------- #

module SchoolRecord

  # A LessonDescription object describes a single lesson and is stored in the
  # SQLite database courtest of DataMapper.
  class LessonDescription
    include DataMapper::Resource
    property :id,          Serial
    property :schoolday,   SchoolDay  # "Sem1 3A Fri"
    property :class_label, String     # "10"
    property :period,      Integer    # (0..6), 0 being before school
    property :description, Text       # "Completed yesterday's worksheet. hw:(4-07)"

    # 'schoolday' is stored as a string, like "Sem1 3A Fri", but is loaded as a
    # real SR::DO::SchoolDay object, as per the DataMapper::Property::SchoolDay
    # class defined above.

    #LessonDescription.raise_on_save_failure = true

    class << LessonDescription
      def find_by_schoolday_and_lesson(schoolday, lesson)
        LessonDescription.first(
          schoolday:   schoolday,
          class_label: lesson.class_label,
          period:      lesson.period
        )
      end
    end  # class << LessonDescription

  end  # class LessonDescription

end  # module SchoolRecord

