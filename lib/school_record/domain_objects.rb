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
    end

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
    end  # class Student

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

  end  # module DomainObjects

  # DO is a useful abbreviation, allowing refs like SR::DO::Note.
  DO = DomainObjects

end
