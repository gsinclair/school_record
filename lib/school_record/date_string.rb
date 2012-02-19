
module SchoolRecord
  # A DateString object simply encapsulates a string like "20 June" or "Fri" or
  # "13A Mon" or "3 days ago".  It can answer questions like: does this string
  # contain a month? a weekday? a day? a semester week? a semester?
  #
  # It provides help for parsing string-based dates, in other words.
  class DateString
    def initialize(string)
      @string = string.strip.dup
      @tags = process_tags
      self.freeze
    end

    def to_s() @string.dup end

    def iso_date?
      @string =~ /\A\d\d\d\d-\d\d-\d\d\Z/
    end

    # The tags you can query are:
    #   sem_week  semester  mday  wday  month  year  iso_date  unknown
    def contains?(*tags)
      tags.all? { |t| @tags.include? t }
    end

    def contains_only?(*tags)
      self.contains?(*tags) and tags.size == @tags.size
    end

    # True iff date string is like "Mon 13A" or "13A Mon". Could include "Sem1"
    # or "Sem2" as well, but doesn't need to.
    # False if anything else is included.
    def semester_style?
      contains_only?(:wday, :sem_week) or contains_only?(:wday, :sem_week, :semester)
    end

    # True iff date string is like "24 May" or "Aug 31".  Nothing else allowed,
    # not even a year.
    def day_month_style?
      contains_only?(:mday, :month)
    end

    def inspect
      "DateString: #{@string.inspect} #{@tags.join ' '}"
    end

    private
    def process_tags
      if iso_date?
        return [:iso_date]
      end
      @string.downcase.split(/[ -]/).map { |token|
        case token
        when /\d\d?[ab]/  then :sem_week
        when /sem[12]/    then :semester
        when /mon|tue|wed|thu|fri/    then :wday
        when /jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec/ then :month
        when /\d\d\d\d/   then :year
        when /\d\d?/      then :mday
        else                   :unknown
        end
      }
    end
  end
end
