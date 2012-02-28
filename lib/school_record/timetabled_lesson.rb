
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
      @lesson = lesson
      @obstacle = obstacle
      validate
    end

    def obstacle?
      @obstacle != nil
    end

    # Retrieves the description for this lesson from the database by searching
    # against the schoolday, class_label and period. Caches for future calls.
    # Returns nil if the corresponding lesson is not found in the database.
    # (Does not cache in that case.)
    def description
      @description ||= (
        ld = LessonDescription.find_by_schoolday_and_lesson(@schoolday, @lesson)
        ld && ld.description
      )
    end

    # E.g. TimetabledLesson: Sem2 13A Tue; 12(4); nil
    # E.g. TimetabledLesson: Sem1 8B Fri; 7(1); Moderator's assembly
    def to_s
      str = "TimetabledLesson: "
      str << @schoolday.full_sem_date
      str << "; " << @lesson.to_s(:brief)
      str << "; " << (@obstacle ? @obstacle.reason : "nil")
      str
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
