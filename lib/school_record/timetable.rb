
module SchoolRecord
  # Timetable is created by the method Timetable.from_yaml, and by no other
  # means.
  class Timetable
    # 'array' contains strings like "_,_,7,_,10,9,_". We turn these into Day
    # objects.
    def initialize(array, valid_class_labels)
      @days = array.map { |x| Day.new(x, valid_class_labels) }
    end
    private :initialize

    # Returns just the class labels.
    # -> [ '10', '10', '7', '12' ]
    def class_labels_only(schoolday)
      @days[schoolday.day_of_cycle - 1].class_labels_only
    end

    # Returns array of classes and the periods they are on.
    # -> [ ['10',0], ['10',1], ['7',2], ['12',5] ]
    def classes(schoolday)
      @days[schoolday.day_of_cycle - 1].classes
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
      Timetable.new(days, valid_class_labels)
    rescue SR::SRError
      sr_int "Timetable.from_hash: invalid timetable config file #{path.to_s}"
    end

    class Day
      # Input: "_,_,7,_,10,9,_"
      def initialize(string, valid_class_labels)
        periods = string.split(',')
        error unless periods.size == 7
        error unless periods.all? { |p| p.in? valid_class_labels or p == '_' }
        @periods = periods   # [ '_', '_', '7', '_', '10', '9', '_' ]
      end

      def class_labels_only
        # Cache this?
        @periods.select { |cl| cl != '_' }
      end

      def classes
        # Cache this?
        (@periods).zip(0..6).select { |cl, pd| cl != '_' }
      end

      def error
        sr_err :invalid_timetable
      end
    end  # class Day
  end  # class Timetable
end  # module SchoolRecord
