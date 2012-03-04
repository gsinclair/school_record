require 'school_record/edit_file/edit_file'

def expected_output
  %{
     +Edit: Sem1 Tue 17A, Sem1 Wed 17A
     +
     +~ Sem1 Tue 17A ========================================================
     +
     +# 10(2) [Moderator's assembly]
     +
     +# 12(3) Tue
     +# Velocity and acceleration
     +
     +~ 11(4) Tue
     +# ...
     +
     +# 7(5) [Moderator's assembly]
     +
     +~ Sem1 Wed 17A ========================================================
     +
     +~ 11(1) Wed
     +# ...
     +
     +~ 12(2) Wed
     +# ...
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
     +# ...
     +
     +vim: ft=school_record
  }.margin
end

D "EditFile::Creator" do
  D.< {
    @db = SR::Database.test
    insert_test_data_efc
  }
  D "#create" do
    sd1 = @db.schoolday("5 June 2012")
    sd2 = @db.schoolday("6 June 2012")
    str = SR::EditFile::Creator.new(@db).create([sd1, sd2])
    Eq str.strip, expected_output.strip
  end
end

def insert_test_data_efc
  adapter = DataMapper.repository(:default).adapter
  adapter.execute "delete from school_record_lesson_descriptions"
  data = %{
    Sem1 17A Tue|12|3|Velocity and acceleration
    Sem1 17A Wed|7|4|Area of a triangle. Started with counting squares, then moved to general diagrams, then to the formula.NLNLSeveral students had trouble with the algebraic letters used in the formula, but they were OK with the general idea.NLNLex:(7-04 Q1 Q3esq,q+a Q4ans)
  }
  stmt = "insert into school_record_lesson_descriptions " \
         "(schoolday, class_label, period, description) " \
         "values (?, ?, ?, ?)"
  data.strip.split("\n").each do |line|
    sd, cl, pd, desc = line.strip.split('|')
    desc.gsub!("NLNL", "\n\n")
    adapter.execute(stmt, sd, cl, pd.to_i, desc)
  end
end
