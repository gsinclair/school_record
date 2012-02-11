module SchoolRecord
  # Represents a single lesson.
  class Lesson
  end
  # Represents a day's worth of lessons, and handles the loading and saving.
  class Lessons
  end
end

# --------------------------------------------------------------------------- #

class SR::Lesson
  attr_reader :schoolday, :class_label, :text
  def initialize(schoolday, class_label, text)
    @schoolday, @class_label, @text = schoolday, class_label, text
  end
end

# --------------------------------------------------------------------------- #

class SR::Lessons
  attr_reader :schoolday
  # lessons_array:
  def initialize(schoolday, lessons_array)
    @schoolday, @lessons = schoolday, lessons
  end

  # Saves this day's lessons to the given output file (Pathname).
  def save(output_file)
    hash = {}
    hash["date"] = @schoolday.date
    hash["lessons"] = @lessons.map { |lesson|
      { "class" => lesson.class_label,
        "desc"  => lesson.text }
    }
    output_file.open('w') do |out|
      out.puts YAML.dump(hash)
    end
  end

  # Generates a Lessons object from a YAML file (Pathname).
  def Lessons.load(input_path, schoolday)
    hash = YAML.load(input_path.read)
    date = hash["date"]
    lessons = hash["lessons"].map { |x|
      class_label = x["class"]
      text = x["desc"]
      Lesson.new(schoolday, class_label, text)
    }
    if schoolday.date != date
      STDERR.puts "Warning: date mismatch in file for schoolday #{schoolday}"
      STDERR.puts "         The date inside the file is #{date}"
    end
    Lessons.new(schoolday, lessons)
  end
end
