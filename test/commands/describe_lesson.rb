require 'stringio'

D "Command::DescribeLesson" do
  D.< {
    @db = SR::Database.test
    @db.clear_sqlite_database
    @out = StringIO.new
  }
  D "Can describe a lesson with 'enter' keyword" do
    dl = SR::Command::DescribeLesson.new(@db, @out)
    dl.run("enter", ['10', "Sem1 4B Thu", "Graphical inequlalities worksheet"])
    Mt @out.string, /Stored description in period 0/
    lessons = SR::LessonDescription.all
    Eq lessons.size, 1
    lesson = lessons.first
    Eq lesson.schoolday.full_sem_date, "Sem1 Thu 4B"
    Eq lesson.class_label, '10'
    Eq lesson.period, 0
    Eq lesson.description, "Graphical inequlalities worksheet"
  end
  D "Can describe a lesson without the 'enter' keyword" do
    dl = SR::Command::DescribeLesson.new(@db, @out)
    dl.run("10", ["Sem1 4B Thu", "Graphical inequlalities worksheet"])
    Mt @out.string, /Stored description in period 0/
    lessons = SR::LessonDescription.all
    Eq lessons.size, 1
    lesson = lessons.first
    Eq lesson.schoolday.full_sem_date, "Sem1 Thu 4B"
    Eq lesson.class_label, '10'
    Eq lesson.period, 0
    Eq lesson.description, "Graphical inequlalities worksheet"
  end
  D "Can insert two lessons for the same class when there is a double period" do
    dl = SR::Command::DescribeLesson.new(@db, @out)
    dl.run("10", ["Sem1 4B Thu", "Desc for pd 0"])
    Mt @out.string, /Stored description in period 0/
    dl = SR::Command::DescribeLesson.new(@db, @out.reopen)
    dl.run("10", ["Sem1 4B Thu", "Desc for pd 1"])
    Mt @out.string, /Stored description in period 1/
    lessons = SR::LessonDescription.all
    Eq lessons.size, 2
    l1, l2 = lessons.shift(2)
    Eq l1.period, 0
    Eq l1.description, "Desc for pd 0"
    Eq l2.period, 1
    Eq l2.description, "Desc for pd 1"
  end
  D "Will not overwrite a lesson that is already described" do
    dl = SR::Command::DescribeLesson.new(@db, @out)
    dl.run("10", ["Sem1 4B Fri", "Quadratic inequalities"])
    Mt @out.string, /Stored description in period 3/
    dl = SR::Command::DescribeLesson.new(@db, @out.reopen)
    dl.run("10", ["Sem1 4B Fri", "Textbook lesson"])
    Mt @out.string, /can't store in pd 3: already described/i
  end
  D "Will not record a lesson that is hit by an obstacle" do
    dl = SR::Command::DescribeLesson.new(@db, @out)
    dl.run("10", ["5 June 2012", "Double angle formulas"])
    Mt @out.string, /can't store in pd 2: Moderator's assembly/
    lessons = SR::LessonDescription.all
    Eq lessons.size, 0
  end
end
