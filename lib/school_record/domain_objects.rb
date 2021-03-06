module SchoolRecord
  module DomainObjects

    # A Name has a first and a last component.
    #   adam = Name.new('Adam', 'Yallop')
    #   adam.first
    #   adam.last
    #   adam.fullname
    #   adam.to_s
    class Name
      def initialize(first, last)
        @first, @last = first, last
      end
      attr_reader :first, :last
      def fullname
        @fullname ||= "#{@first} #{@last}"
      end
      def to_s() fullname end
      def hash
        [self.class, @first, @last].hash
      end
      def eql?(other)
        self.equal?(other) ||
          self.class == other.class &&
          self.first == other.first &&
          self.last  == other.last
      end
      alias == eql?
    end

    # --------------------------------------------------------------------------- #

    # A Student has a name and a class label.
    #   adam = Name.new('Adam', 'Yallop')
    #   std = Student.new(adam, '10C')
    #   std.first; std.last; std.fullname; std.name; std.class_label
    class Student
      def initialize(name, class_label)
        @name, @class_label = name, class_label
      end
      attr_reader :name, :class_label
      def first()    @name.first    end
      def last()     @name.last     end
      def fullname() @name.fullname end
      def to_s
        "#{first} #{last} (#{class_label})"
      end
      def hash
        [self.class, @name, @class_label].hash
      end
      def eql?(other)
        self.equal?(other) ||
          self.class.equal?(other.class) &&
          self.name == other.name        &&
          self.class_label == other.class_label
      end
      alias == eql?
    end  # class Student

    # --------------------------------------------------------------------------- #

    # A Note has a date, a Student, and some text.
    #   adam = Name.new('Adam', 'Yallop')
    #   adam = Student.new(adam, '10C')
    #   note = Note.new( Date.today, adam, "Poor assignment submission" )
    class Note
      def initialize(date, student, text)
        @date, @student, @text = date, student, text
      end
      attr_reader :date, :student, :text
    end  # class Note

    # --------------------------------------------------------------------------- #

    # A SchoolClass has a label ('7', '10C', etc.), a full name ('7 Mathematics B2'),
    # and a list of student names (array of Name objects). The key purpose of
    # SchoolClass is to resolve a name fragment.
    #
    #   resolve(name_fragment)  -> [Student]
    #   resolve!(name_fragment) -> Student or raise SRError
    #
    #   resolve('Jane')
    #     # -> [Student('Jane Cooper', '10C'), Student('Janet Ma', '10C')]
    #
    #   resolve('Pet')
    #     # -> Will resolve "Ursula Peterson", but only if no first names in the
    #     #    class match 'Pet'. So first names are searched first, and if any
    #     #    are found, then last names are not searched at all.
    #
    #   resolve('ASmi')
    #     # Will resolve a student named 'Adam Smith', for instance.
    #
    #   resolve('ToB')
    #     # Tony Barber?  Tom Bunyan?
    #
    # To make things easier, the fragment can have one or two capital letters.
    # Not none, and not more than two. And no spaces. An SRError results if the
    # fragment is invalid. 
    class SchoolClass
      def initialize(label, full_label, class_name, student_names)
        @label, @full_label, @class_name, @student_names =
          label, full_label, class_name, student_names
      end
      attr_reader :label, :full_label, :class_name
      # #resolve returns an array of students who match the name fragment given.
      def resolve(name_fragment)
        first, last =
          case name_fragment
          when /^([A-Z][a-z]*)$/
            [$1, nil]
          when /^([A-Z][a-z]*)([A-Z][a-z]*)$/
            [$1, $2]
          else
            sr_err :invalid_name_fragment, name_fragment
          end
        names =
          if first and last
            @student_names.select { |n|
              n.first.start_with? first and n.last.start_with? last
            }
          else
            result = @student_names.select { |n| n.first.start_with? first }
            if result.empty?
              result = @student_names.select { |n| n.last.start_with? first }
            end
            result
          end
        names.map { |name| SR::DO::Student.new(name, @label) }
      end
      # #resolve! insists on there being a unique match and raises an error if
      # there's no match and a different error if there are multiple matches.
      def resolve!(name_fragment)
        students = resolve(name_fragment)
        case students.size
        when 0
          sr_err :no_student_match, name_fragment
        when 1
          students.first
        else
          sr_err :multiple_students_match, name_fragment, @label, students
        end
      end
    end  # class SchoolClass

    # --------------------------------------------------------------------------- #

    # SchoolDay represents a date in the school calendar. It encompasses
    # regular-style date (2012-07-29) and semester-style date (Sem1 Fri 11A).
    # It is a dumb object, believing whatever you tell it.  The Calendar class
    # is responsibile for knowing the term times and determining what date
    # corresponds to what week, etc.  This class just conveys values.
    class SchoolDay
      def initialize(date, semester, week)
        unless Date === date and semester.in? 1..2 and week.in? 1..30
          sr_err :argument_error, "SchoolDay#initialize"
        end
        @date, @semester, @week = date, semester, week
      end

      def <=> (other)
        self.date <=> other.date
      end
      include Comparable

      def ==(other)
        self.class == other.class and
          self.date == other.date and
          self.semester == other.semester and
          self.week == other.week
      end

      def hash
        [@date, @semester, @week].hash
      end

      # -> Date
      def date() @date end

      # -> 1 or 2
      def semester() @semester end

      # -> 1..4
      def term() sr_int "SchoolDay#term is not implemented" end

      # -> 1..20  (more like 1..18 or 1..19)
      def week() @week end

      # -> "Mon 11A"
      def weekstr() "#{week}#{a_or_b}" end

      # -> "Mon", "Tue", ...
      def day() @date.strftime("%a") end

      # -> "Jan", "Feb", ...
      def month() @date.strftime("%b") end

      # -> 2012, ...
      def year() @date.year end

      # -> "A", "B"
      def a_or_b() @week.odd?  ? 'A' : 'B' end

      # -> "Mon 11A (28 Sep)"
      def to_s() "#{day} #{weekstr} (#{date.day} #{month})" end
      def inspect() "SD<#{to_s}>" end

      # -> 1..10
      def day_of_cycle
        n = @date.wday    # 1..5 (for Mon..Fri)
        n += 5 if a_or_b == 'B'
        n
      end

      # sem_date()           # -> "Mon 11A"
      # sem_date(true)       # -> "Sem2 Mon 11A"
      # sem_date(:semester)  # -> "Sem2 Mon 11A"
      def sem_date(include_semester=false)
        str = "#{day} #{weekstr}"
        if include_semester == true or include_semester == :semester
          str = "Sem#{@semester} " + str
        end
        str
      end

      def full_sem_date()  sem_date(:semester)  end
      def short_sem_date() sem_date(false)      end
    end  # class SchoolDay

    # --------------------------------------------------------------------------- #

    # A Lesson object simply encapsulates a schoolday, a class label, and a
    # period. See TimetabledLesson (future implementation) for a more
    # significant object along these lines. This class is simply a value object
    # to avoid having to pass multiple parameters around.
    #
    # The schoolday and period properties may be nil (see for example the use of
    # this class in Obstacle), but an error is raised if class_label is nil.
    class Lesson
      attr_reader :class_label, :period
      def initialize(class_label, period)
        sr_int "Incomplete Lesson object (#{class_label})" if class_label.nil?
        @class_label, @period = class_label, period
      end
      def to_s(format=:full)
        case format
        when :full
          "Lesson: cl=#{class_label.inspect} pd=#{period.inspect}"
        when :brief
          @class_label + (@period ? "(#@period)" : "")
        end
      end
      def inspect() to_s end
      # str: 10(3)
      def Lesson.parse(str)
        if str.strip[/^(\w+)\((\d)\)$/]
          class_label, period = $1, $2.to_i
          Lesson.new(class_label, period)
        else
          sr_int "Can't parse Lesson string: #{str}"
        end
      end
      def ==(other)
        [self.class, @class_label, @period] ==
          [other.class, other.class_label, other.period]
      end
      def hash
        [self.class, @class_label, @period].hash
      end
    end  # class Lesson

    # --------------------------------------------------------------------------- #

  end  # module DomainObjects

  # DO is a useful abbreviation, allowing refs like SR::DO::Note.
  DO = DomainObjects

end
