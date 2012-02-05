
module SchoolRecord
  # Timetable is created by the method Timetable.from_yaml, and by no other
  # means.
  class Timetable
    def initialize(array)
      @days = array
    end
    private :initialize

    def classes(schoolday)
      @days[schoolday.day_of_cycle - 1]
    end

    # Takes a Pathname object.
    # valid_class_labels is an array like ['7', '10', '11', '12'].
    # An error is thrown if the data is invalid.
    def Timetable.from_yaml(path, valid_class_labels)
      hash = YAML.load(path.read)
      weekA = hash["WeekA"]
      days = %w(Mon Tue Wed Thu Fri).map { |day| weekA[day] }
      weekB = hash["WeekB"]
      days += %w(Mon Tue Wed Thu Fri).map { |day| weekB[day] }
      unless Array === days and days.size == 10 and days.first.is_a? String
        sr_int "Timetable.from_hash: invalid timetable config file #{path.to_s}"
      end
      # days now looks like [ "7,10,9", "12,11,7,7", ... ]
      # but we want [ ['7','10','9'], ['12','11','7','7'], ... ]
      days.map! { |str| str.split(',') }
      if days.all? { |d| d.all? { |c| c.in? valid_class_labels } }
        return Timetable.new(days)
      else
        sr_int "Timetable.from_hash: invalid timetable config file #{path.to_s}"
      end
    end
  end  # class Timetable
end  # module SchoolRecord
