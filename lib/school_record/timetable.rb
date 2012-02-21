
module SchoolRecord
  # Timetable is created by the method Timetable.from_yaml, and by no other
  # means.
  class Timetable
    # 'array' contains strings like "_,_,7,_,10,9,_". We turn these into Day
    # objects.
    def initialize(array, valid_class_labels)
      @days = array.map { |x| Day.from_string(x, valid_class_labels) }
    end
    private :initialize

    # Designed for testing.  Emits a string like "7(1), 11(3), 11(4), 10(6)".
    def lessons_export_string(day_of_cycle)
      validate(day_of_cycle)
      @days[day_of_cycle - 1].lessons_export_string
    end

    # Returns [Lesson].
    def lessons(day_of_cycle)
      validate(day_of_cycle)
      @days[day_of_cycle - 1].lessons
    end

    def validate(day_of_cycle)
      sr_int "Invalid day_of_cycle: #{day_of_cycle}" unless day_of_cycle.in? (1..10)
    end
    private :validate

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
        sr_err :invalid_timetable, path.to_s
      end
      Timetable.new(days, valid_class_labels)
    rescue SR::SRError
      sr_err :invalid_timetable, path.to_s
    end


    class Day
      # Input: "_,_,7,_,10,9,_"
      # Seven periods in a day (enforced): first one is before school.
      def Day.from_string(string, valid_class_labels)
        @error = lambda { sr_err :invalid_timetable, string }
        periods = string.split(',')
        error[] unless periods.size == 7
        error[] unless periods.all? { |p| p.in? valid_class_labels or p == '_' }
        lessons = periods.map.with_index { |cl, pd|
          if cl == '_'
            nil
          else
            SR::DO::Lesson.new(cl, pd)
          end
        }.compact
        Day.new(lessons)
      end

      def initialize(lessons)
        @lessons = lessons
      end

      # Designed for testing.
      def lessons_export_string
        @lessons.map { |l| "#{l.class_label}(#{l.period})" }.join(', ')
      end

      def lessons
        # Is 'dup' necessary?  Is this method even necessary? Is there a better API?
        @lessons.dup
      end
    end  # class Day
  end  # class Timetable
end  # module SchoolRecord
