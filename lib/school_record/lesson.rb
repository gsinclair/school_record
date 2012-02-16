require 'data_mapper'

module SchoolRecord
  # Represents a single lesson.
  class Lesson
    include DataMapper::Resource
    property :id,          Serial
    property :schoolday,   String     # "Sem1 3A Fri"
    property :class_label, String     # "10"
    property :description, Text       # "Completed yesterday's worksheet. hw:(4-07)"
  end
end

# --------------------------------------------------------------------------- #

class SR::Lesson
end
