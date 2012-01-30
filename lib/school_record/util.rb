
class Object
  # Why oh why is this not in the language?
  def in?(collection)
    collection.include? self
  end
end

module SchoolRecord
  class Util
    # Returs a string like "13 Jan" or " 2 Mar" (note blank padding).
    def Util.day_month(date)
      date.strftime("%e %b")
    end

    def Util.weekday?(date)
      @weekdays ||= (1..5)
      date.wday.in? @weekdays
    end

    def Util.weekend?(date)
      @weekends ||= [0,6]
      date.wday.in? @weekends
    end

    def Util.date(arg)
      case arg
      when String then Date.parse(arg)
      when Date   then arg
      else sr_int "Invalid argument: #{arg.inspect}"
      end
    end
  end
end
