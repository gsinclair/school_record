
module SchoolRecord

  # A LessonDescription object describes a single lesson and is stored in the
  # SQLite database courtest of DataMapper.
  class LessonDescription
    include DataMapper::Resource
    property :id,          Serial
    property :schoolday,   String     # "Sem1 3A Fri"
    property :class_label, String     # "10"
    property :period,      Integer    # (0..6), 0 being before school
    property :description, Text       # "Completed yesterday's worksheet. hw:(4-07)"
  end

end  # module SchoolRecord
