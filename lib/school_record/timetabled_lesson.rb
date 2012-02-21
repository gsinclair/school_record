
module SchoolRecord

  # TimetabledLesson is a heavyweight object in this system. If it exists, it is
  # on the timetable. If there is no obstacle, the lesson is happening. This
  # object is therefore very important for the code that stores lesson
  # descriptions in the database. Accessed through:
  #
  #   Database#timetabled_lessons(day)
  #
  # By comparison, the lightweight DO::Lesson object is only meant for passing
  # values around, like to TimetabledLesson.new(lesson, obstacle=nil).
  class TimetabledLesson
    attr_reader :schoolday, :class_label, :period, :obstacle

    def initialize(schoolday, lesson, obstacle=nil)
      @schoolday, @class_label, @period =
        schoolday, lesson.class_label, lesson.period
      @obstacle = obstacle
      validate
    end

    def obstacle?
      @obstacle != nil
    end

    private
    def validate
      error "schoolday" unless DO::SchoolDay === @schoolday
      error "class_label" unless String === @class_label
      error "period" unless Integer === @period and @period.in?(0..6)
      error "obstacle" unless @obstacle.nil? or Obstacle === @obstacle
    end

    def error(msg)
      values = [@schoolday, @class_label, @period, @obstacle]
      sr_err :invalid_timetabled_lesson, values, msg
    end
  end  # class TimetabledLesson

end  # module SchoolRecord
