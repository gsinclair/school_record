require 'chronic'

module SchoolRecord
  class Calendar
    class Term; end
    class Semester; end
  end
end

# --------------------------------------------------------------------------- #

# Term is a value object whose functions are:
#  * know when it starts and finishes
#  * know what number term it is
#  * know how many weeks are in the term
#  * know whether a date is a term date (weekends excluded)
#  * determine the date of the seventh Wednesday, for instance
#  * determine the week and day of 2012-05-23, for instance
class SR::Calendar::Term
  # Integer, Date, Date
  def initialize(number, start, finish)
    sr_err :invalid_object, "Term: number == #{number}" unless number.in? 1..4
    sr_err :invalid_object, "Term: finish < start" if finish < start
    @number, @start, @finish = number, start, finish
    @monday_of_first_week = monday_of_first_week
    @weeks = (1..number_of_weeks)
    self.freeze
  end

  attr_reader :number, :start, :finish

  def semester
    case @number
    when 1,2 then 1
    when 3,4 then 2
    end
  end

  def number_of_weeks
    (@finish.cweek - @start.cweek) % 52 + 1
  end

  def include?(date)
    date = SR::Util.date(date)
    @start <= date and date <= @finish and SR::Util.weekday?(date)
  end

  # date(week: 7, day: 2)
  # Returns nil if the resulting date is not in the term.
  def date(args)
    week, day = args[:week], args[:day]
    unless day and week and week.in? @weeks and day.in? (1..5)
      sr_int "Invalid argument: #{args.inspect}"
    end
    date = monday_of_first_week + (week-1)*7 + (day-1)
    if self.include? date then date else nil end
  end

  # week_and_day(date) -> [9,4]  week 9, day 4 (Thu)
  def week_and_day(date)
    date = SR::Util.date(date)
    return nil unless self.include? date
    ndays = (date - monday_of_first_week).to_i
    week  = ndays / 7 + 1
    day   = ndays % 7 + 1
    [week, day]
  end

  private
  def monday_of_first_week
    date = @start
    until date.wday == 1
      date -= 1
    end
    date
  end
end  # class SR::Calendar::Term

# --------------------------------------------------------------------------- #

class SR::Calendar::Semester
  def initialize(number, terms)
    @number = number
    @terms = terms
    @t1 = @terms[0]
    @t2 = @terms[1]
    @number_of_weeks = @t1.number_of_weeks + @t2.number_of_weeks
    number_of_weeks
    weeks_map
    self.freeze
  end

  def number
    @number
  end

  def number_of_weeks
    @number_of_weeks
  end

  def include?(date)
    @terms[0].include? date or @terms[1].include? date
  end

  # date(week: 13, day: 5)
  def date(args)
    week, day = args[:week], args[:day]
    unless day and week and week.in? (1..number_of_weeks) and day.in? (1..5)
      sr_int "Invalid argument: #{args.inspect}"
    end
    t1weeks, t2weeks = weeks_map   # [ (1..10), (11..19) ]
    if week.in? t1weeks
      @t1.date week: week, day: day
    elsif week.in? t2weeks
      @t2.date week: (@t1.number_of_weeks + week), day: day
    else
      sr_int "Can't handle case of week == #{week}"
    end
  end

  # week_and_day(date) -> [17,1]  week 17, day 1 (Mon)
  # Returns nil if the given date is not in this term.
  def week_and_day(date)
    if not self.include? date
      return nil
    elsif (week_and_day = @t1.week_and_day(date))
      return week_and_day
    elsif (week_and_day = @t2.week_and_day(date))
      weekm day = week_and_day
      week += @t1.number_of_weeks
      return [week, day]
    else
      sr_int "Impossible case (date == #{date})"
    end
  end

  private
  # -> [ 1..10, 11..19 ]
  def weeks_map
    @weeks_map ||= (
      t1w = @t1.number_of_weeks
      [ (1..t1w) , (t1w+1 .. number_of_weeks) ]
    )
  end
end  # class SR::Calendar::Semester

# --------------------------------------------------------------------------- #

class SR::Calendar
  def initialize(config_file)
    @today = []
    _init(config_file)
  end

  # Set what "today" is -- for testing. Returns its argument.
  def today=(date)
    @today << date
    date
  end

  # Get today's date (Date object), for figuring out what semester it is, etc.
  def today
    if @today.empty?
      today.last
    else
      Date.today
    end
  end

  # Reset the previous value for "today" -- when you've finished testing.
  # Returns self.
  def reset_today
    today.pop
    self
  end
  
  # Input: "6 Jun" or "2012-06-01" or "11A-Mon" or "11A Mon" or "Sem2-11A-Mon"
  #        or "Sem2 11A Mon" or ...
  # Output: a SchoolDay object encapsulating the calendar date and term date.
  #
  # e.g.
  #   calendar.schoolday("2012-02-16").to_s    # -> "Thu 3A (16 Feb)"
  #   calendar.schoolday("Sem2 14B Mon").to_s  # -> "Mon 14B (29 Oct)"
  def schoolday(string)
    date = attempt_to_parse_date_string(string)
    if date
      term, week = determine_term_and_week(date)
      return SchoolDay.new(date, term, week)
    else
      term, week, day = extract_term_date_info(string)
      sr_err :invalid_term_date, string if term.nil?
      # FIXME the next line is wrong -- it needs date, term, week!
      return SchoolDay.new(term, week, day)
    end
  end

  private

  # Three outcomes:
  # 1. If a valid date (this year) can be divined from the string, return Date.
  # 2. If the string represents a date _not_ this year, raise exception.
  # 3. If the string does not appear to represent a calendar date, return nil.
  def attempt_to_parse_date_string(string)
    c = Chronic.parse(string, now: today().to_time)
      # This will catch many 'dates' like:
      #   yesterday, Fri, two weeks ago, may 26, 3rd thursday this september, ...
    if c.nil?
      return nil
    elsif c.year != Date.today.year
      sr_err :invalid_date_not_this_year, string
    else
      return c.to_date
    end
  end

  def determine_term_and_week(date)
    [4, 1]
  end

  def extract_term_date_info(string)
    [4, 3, 2]
  end

  def _init(config_file)
    data = YAML.load(config_file.read)
    @staff_days = data["StaffDays"].map { |str| Date.parse(str) }
    @public_holidays = data["PublicHolidays"].map { |str| Date.parse(str) }
    @speech_day = Date.parse( data["SpeechDay"] )
    @terms = ["Term1", "Term2", "Term3", "Term4"].map { |key|
      number = key[/Term(\d)/, 1]
      start, length, finish = data[key]
      start, finish = Date.parse(start), Date.parse(finish)
      Term.new(number, start, finish)
    }
    @semesters = [Semester.new(@terms[0..1], @terms[2..3])]
  end

  # Return 1..4 or nil.
  def which_term(date)
    term = @terms.find { |t| t.include? date }
    term ? term.number : nil
  end

  # Return 1..2 or nil.
  def which_semester(date)
    case which_term(date)
    when 1,2 then 1
    when 3,4 then 2
    when nil then nil
    end
  end

  # Return :school_day, :weekend, :school_holiday, :staff_day,
  #        :public_holiday, :speech_day.
  def what_kind_of_day(date)
    if date.in? @public_holidays
      return :public_holiday
    elsif date.in? @staff_days
      return :staff_day
    elsif date == @speech_day
      return :speech_day
    elsif SR::Util.weekend?(date)
      return :weekend
    elsif @terms.any? { |t| t.include? date}
      return :school_day
    else
      return :school_holiday
    end
  end

  def school_day?(date)
    what_kind_of_day(date) == :school_day
  end

  def non_school_day?(date)
    what_kind_of_day(date) != :school_day
  end

end  # class SR::Calendar


