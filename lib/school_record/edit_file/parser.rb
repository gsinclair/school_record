
module SR::EditFile
  # This associates a schoolday with an array of LessonVO objects. A single
  # DayVO therefore contains a user's input of lesson descriptions for one whole
  # day.
  class DayVO
    attr_reader :schoolday, :lessons
    def initialize(schoolday)
      @schoolday, @lessons = schoolday, []
    end
    def add_lesson(lesson, description)
      @lessons << LessonVO.new(lesson, description)
    end
  end

  # This simply bundles a lesson (class and period) with a description for the
  # sake of parsing the user's input.
  class LessonVO
    attr_reader :lesson, :description
    def initialize(lesson, description)
      @lesson, @description = lesson, description
    end
  end

  # Takes the user's input (a long string) and returns an array of DayVO via
  # the #parse method. This ignores comments.
  #
  #   SR::EditFile::Parser.new(db).parse(string)
  #    -> DayVO[Thu 3A]
  #         LessonVO[10(0), "Function notation"]
  #         LessonVO[10(1), "Revised for test tomorrow"]
  #         LessonVO[7(2), "Number patterns..."]
  #       DayVO[Fri 3A]
  #         LessonVO[12(3), "Logs and exponentials introduction"]
  #         ...
  #       ...
  #
  # Paragraphs in the lesson descriptions are marked by <PARA>, which tends to
  # be surrounded by a space. Code that wants to display these descriptions will
  # want to do something like:
  #
  #   description = description.gsub /\s*<PARA>\s*/, "\n\n"
  #
  # The destination for these descriptions is the database, anyway. It's
  # probably good to leave the PARA codes in there.
  class Parser
    def initialize(db)
      @db = db
    end
    def parse(string)
      days = []
      lines = string.split("\n")
      lines.shift if lines.first =~ /^Edit: /
      current_day = current_lesson = description = nil
      loop do
        line = lines.shift
        break if line.nil?
        trace :line, binding
        case line.strip
        when ""   then next
        when /^#/ then next
        when /^~ Sem/
          current_day = DayVO.new(parse_day(line))
          days << current_day
        when /^~ \w{1,7}\(\d\) \w\w\w$/
          current_lesson = SR::DO::Lesson.parse(line.split[1])
          description = extract_description(lines)
          current_day.add_lesson(current_lesson, description)
        end
      end
      days
    end  # parse

    private
    def parse_day(line)
      if line[/~ (Sem\d \w+ \w+) ===*/]
        @db.schoolday($1)
      else
        sr_int "Invalid line: #{line}"
      end
    end
    def parse_lesson(line)
      if line[/^~ (\S+) \w\w\w/]
        SR::DO::Lesson.parse($1)
      else
        sr_int "Invalid line: #{line}"
      end
    end
    def extract_description(lines)
      # Read lines until we get to a directive or the end. Ignore comments.
      desc_lines = []
      loop do
        if lines.empty? or lines.first =~ /^~ /
          break
        else
          line = lines.shift
          next if line =~ /^#/
          desc_lines << line.strip
        end
      end
      # Return a string where paragraph breaks are marked with <PARA> and there
      # are no newlines.
      words = []
      desc_lines.each do |line|
        if line.empty?
          words << "<PARA>"
        else
          words << line.split
        end
      end
      words = words.flatten.join(' ')
      words = words.gsub /(\s*<PARA>\s*)+$/, ""
      words.strip
    end
  end  # class Parser
end  # module SR::EditFile
