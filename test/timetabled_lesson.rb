
# TimetabledLesson is tested in test/database.rb because Database#timetabled_lesson 
# is the main/only way of creating these objects.
#
# The only real thing to test here is storage and retrieval of lessons
# descriptions from the database. To do that we need some data in the test
# database.

D "TimetabledLesson" do
  D.<< {
    @db = SR::Database.test
    insert_test_data
  }
  D "#description" do
    # Normally you would get TimetabledLesson objects via Database#timetabled_lesson.
    # That is tested in test/database.rb, but the _description_ functionality is
    # not tested there. We need to create TimetabledLesson objects directly,
    # using a SchoolDay and Lesson object. (Optionally an Obstacle as well, but
    # that is unnecessary here: that functionality is tested in Database.)
    sd1 = @db.schoolday("Sem1 1A Fri")
    lesson1 = SR::DO::Lesson.new('10', 5)
    lesson2 = SR::DO::Lesson.new('7', 6)
    sd2 = @db.schoolday("Sem1 2B Mon")
    lesson3 = SR::DO::Lesson.new('10', 0)
    lesson4 = SR::DO::Lesson.new('7', 1)   # No data for this one.

    tl1 = SR::TimetabledLesson.new(sd1, lesson1)
    tl2 = SR::TimetabledLesson.new(sd1, lesson2)
    tl3 = SR::TimetabledLesson.new(sd2, lesson3)
    tl4 = SR::TimetabledLesson.new(sd2, lesson4)

    N! tl1.description
    Mt tl1.description, /Overview of number systems/
    Eq tl2.description, "start:(Whole Numbers) Introduction to high school."
    Eq tl3.description, "Marked arithmetic pretest. Rushed through 1.1 to 1.8. Absolute values."
    Eq tl4.description, nil

    D "caches" do
      sd1 = @db.schoolday("Sem1 1A Fri")
      lesson2 = SR::DO::Lesson.new('7', 6)
      tl = SR::TimetabledLesson.new(sd1, lesson2)
      d1 = tl.description
      d2 = tl.description
      Id d1, d2
    end
  end

  D "#store_description" do
    sd = @db.schoolday "Sem1 2A Tue"
    lesson = SR::DO::Lesson.new('12', 3)
    tl = SR::TimetabledLesson.new(sd, lesson)
    # Start by asserting that it doesn't already have a description associated.
    N tl.description
    # Now store one.
    tl.store_description "Simpson's rule"
    # Check that it is stored.
    Eq tl.description, "Simpson's rule"
    # But that could be cached. Try a fresh object.
    Eq SR::TimetabledLesson.new(sd, lesson).description, "Simpson's rule"
    # Let's be really paranoid and access the database ourselves.
    ld = SR::LessonDescription.all(schoolday: sd, class_label: '12', period: 3)
    Eq ld.size, 1
    Eq ld.first.description, "Simpson's rule"
  end
  D "doesn't overwrite existing record (raises exception)" do
    sd = @db.schoolday "Sem1 2A Tue"
    lesson = SR::DO::Lesson.new('12', 3)
    tl = SR::TimetabledLesson.new(sd, lesson)
    E(SR::SRError) { tl.store_description "..." }
    Mt Whitestone.exception.message, /Lesson description exists/
  end
end

def insert_test_data
  adapter = DataMapper.repository(:default).adapter
  adapter.execute "delete from school_record_lesson_descriptions"
  data = %{
    Sem1 1A Fri|10|5|start:(Arithmetic) Overview of number systems. Arithmetic pretest.
    Sem1 1A Fri|7|6|start:(Whole Numbers) Introduction to high school.
    Sem1 2B Mon|10|0|Marked arithmetic pretest. Rushed through 1.1 to 1.8. Absolute values.
  }
  stmt = "insert into school_record_lesson_descriptions " \
         "(schoolday, class_label, period, description) " \
         "values (?, ?, ?, ?)"
  data.strip.split("\n").each do |line|
    sd, cl, pd, desc = line.strip.split('|')
    adapter.execute(stmt, sd, cl, pd.to_i, desc)
  end
end
