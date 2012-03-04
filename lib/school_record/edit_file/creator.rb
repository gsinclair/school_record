require 'stringio'
require 'facets/string/word_wrap'

class SchoolRecord::EditFile::Creator

  NL = "\n"
  NLNL = "\n\n"
  EQUALS = "=" * 56

  # Argument: db is a Database that enables us to look up the lessons timetabled
  # for the required days.
  def initialize(db)
    @db = db
  end

  # Argument: schooldays is an array of SchoolDay objects.
  # Return: a string containing the file contents for those school days. Example
  # output:
  #
  #   # Edit: Sem1 Tue 3A, Sem1 Wed 3A
  #
  #   ~ Sem1 Tue 3A ========================================================
  #
  #   ~ 10(2) Tue
  #   # ...
  #
  #   # ~ 12(3) Tue
  #   # Simpson's rule worksheet (concluded), followed by practice questions.
  #   # ex:(3.2)
  #
  #   # 11(4) [Exams]
  #
  #   ~ 7(5) Tue
  #   # ...
  #
  #   ~ Sem1 Wed 3A ========================================================
  #
  #   # ~ 11(1) Wed
  #   # start:(AM2) Introduction to linear equations and graphs. ex:(7.1)
  #
  #   ~ 12(2) Wed
  #   # ...
  #
  #   ~ 7(4) Wed
  #   # ...
  #
  #   # ~ 10(5) Wed
  #   # Equations with fractions. ex:(3.4)
  #
  #   # vim: ft=school_record
  #
  # The "# ..." are meant literally: the user will replace them with text.
  # Comments are prefaces with a '#', directives with a '~'. Lessons that are
  # already described are included as comments. Lessons that are obstacled are
  # also mentioned briefly as comments.
  def create(schooldays)
    # The main thing is to get the timetabled lessons for the schooldays and
    # present the information in the textual form shown above. I guess lines
    # should be wrapped at 76 characters or something like that.
    out = StringIO.new
    header = "Edit: " + schooldays.map { |s| s.full_sem_date }.join(', ')
    out << header << NLNL
    schooldays.each do |sd|
      out << schoolday_info(sd) << NL
    end
    out << "vim: ft=school_record\n"
    out.string
  end

  private

  # ~ Sem1 Wed 3A ======== etc.
  #
  # plus the details of each lesson.
  def schoolday_info(sd)
    out = StringIO.new
    out << "~ #{sd.full_sem_date} #{EQUALS}" << NL
    @db.timetabled_lessons(sd).each do |tl|
      out << NL << lesson_info(tl) << NL
    end
    out.string
  end

  # Returns the string for a single lesson which may have:
  # * an existing description, in which case everything is commented
  # * an obstacle, in which case a brief description is commented
  # * no existing description
  def lesson_info(tl)
    if tl.obstacle?
      "# #{tl.lesson.to_s(:brief)} [#{tl.obstacle.reason}]"
    elsif tl.description
      format_existing_description(tl)
    else
      "~ #{tl.lesson.to_s(:brief)} #{tl.schoolday.day}" << NL << "# ..."
    end
  end

  # Contains the directive, the lesson and day, and the description, on as many
  # lines as necessary, but the whole thing is commented out.
  def format_existing_description(tl)
    out = StringIO.new
    out << "#{tl.lesson.to_s(:brief)} #{tl.schoolday.day}" << NL
    out << break_lines(tl.description, 74).strip
    out.string.gsub(/^/, '# ')
  end

  def break_lines(string, max_len)
    out = StringIO.new
    string.strip.split(NLNL).map { |para|
      para.strip.word_wrap(max_len)
    }.join(NL)
  end

end  # class SchoolRecord::EditFile::Creator
