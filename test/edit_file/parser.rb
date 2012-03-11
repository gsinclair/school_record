def input_string
  str = %{
    +Edit: Sem1 Tue 17A, Sem1 Wed 17A
    +
    +~ Sem1 Tue 17A ========================================================
    +
    +# 10(2) [Moderator's assembly]
    +
    +# 12(3) Tue
    +# Velocity and acceleration [this text there already; we don't process it]
    +
    +~ 11(4) Tue
    +Tax scales; finding   tax payable for a given taxable income from a
    +table. Discussion of gradients when the table information is drawn.
    +
    +ex:(5C Q2-4esq)
    +
    +# 7(5) [Moderator's assembly]
    +
    +~ Sem1 Wed 17A ========================================================
    +
    +~ 11(1) Wed
    +More work on the graphical aspects of tax tables. Tax deductions.
    +
    +~ 12(2) Wed
    +Radian measure. Ruler demonstration. Examples converting between
    +radians and degrees.
    +
    +# 7(4) Wed
    +# Area of a triangle. Started with counting squares, then moved to general
    +# diagrams, then to the formula.
    +#
    +# Several students had trouble with the algebraic letters used in the
    +# formula, but they were OK with the general idea.
    +#
    +# ex:(7-04 Q1 Q3esq,q+a Q4ans)
    +
    +~ 10(5) Wed
    +Working lesson.
    +
    +#vim: ft=school_record
  }.margin
end

D "EditFile::Parser" do
  D.< {
    @db = SR::Database.test
    @parser = SR::EditFile::Parser.new(@db)
  }
  D "#parse" do
    data = @parser.parse(input_string)
    Ko data, Array
    Eq data.size, 2
    day = data.shift
    Ko day, SR::EditFile::DayVO
    Eq day.schoolday, @db.schoolday("Sem1 Tue 17A")
    Eq day.lessons.size, 1
    Eq day.lessons[0].lesson, SR::DO::Lesson.new('11',4)
    Eq day.lessons[0].description, \
      "Tax scales; finding tax payable for a given taxable income from a table. Discussion " \
      "of gradients when the table information is drawn. <PARA> ex:(5C Q2-4esq)"
    day = data.shift
    Ko day, SR::EditFile::DayVO
    Eq day.lessons.size, 3
    Eq day.lessons[0].lesson, SR::DO::Lesson.new('11',1)
    Eq day.lessons[0].description, \
      "More work on the graphical aspects of tax tables. Tax deductions."
    Eq day.lessons[1].lesson, SR::DO::Lesson.new('12',2)
    Eq day.lessons[1].description, \
      "Radian measure. Ruler demonstration. Examples converting between " \
      "radians and degrees."
    Eq day.lessons[2].lesson, SR::DO::Lesson.new('10',5)
    Eq day.lessons[2].description, \
      "Working lesson."
  end
end

