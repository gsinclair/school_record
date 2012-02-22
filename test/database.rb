
D "Database" do
  D "Can be loaded (test database)" do
    db = SR::Database.test
    Ko db, SR::Database
  end

  D "When it's loaded" do
    D.<< { @db = SR::Database.test }
    D "It can resolve student names" do
      students = @db.resolve_student('7', 'Kelly')
      Ko students, Array
      Eq students.size, 1
      Eq students.first.fullname, "Kelly-Maree Bakoulis"
    end
    D "It can resolve! student names" do
      student = @db.resolve_student!('12', 'ISmy')
      Ko student, SR::DO::Student
      Eq student.fullname, "Isabella Smythe"
    end
    D "It can access the saved notes ('notes' method)" do
      notes = @db.notes('10')
      Ko notes, Array
      Eq notes.size, 3
      Eq notes.first.student.fullname, "Mikaela Achie"
      Eq notes.first.text,             "Missing equipment"
      notes = @db.notes('12')
      Eq notes.size, 3
      Eq notes[0].student.fullname, "Isabella Henderson"
      Eq notes[0].text,             "Assignment not submitted"
      Eq notes[1].student.fullname, "Isabella Henderson"
      Eq notes[1].text,             "Assignment submitted late"
      Eq notes[2].student.fullname,  "Anna Burke"
      Eq notes[2].text,              "Good work on board"
      notes = @db.notes('12', 'ABur')
      Eq notes.size, 1
      Eq notes.first.student.fullname,  "Anna Burke"
      Eq notes.first.text,              "Good work on board"
    end
    # The test block below is disabled because the 'classes' method doesn't
    # exist. I will test timetabled_lesson when it is implemented.
    xD "It can look up the classes for any date" do
      D.< {
        @db.calendar.today = Date.new(2012, 8, 23)   # Sem2 Thu 6B
      }
      D.> { @db.calendar.reset_today }
      D "School days" do
        Eq @db.classes('today'),         %w[10 10 7 11]
        Eq @db.classes('yesterday'),     %w[12 11 10 7]
        Eq @db.classes('Monday'),        %w[10 7 12 11]
        Eq @db.classes('Mon'),           %w[10 7 12 11]
        Eq @db.classes('Fri'),           %w[11 11 10 7]
        Eq @db.classes('24 May'),        %w[10 10 7 12]
        Eq @db.classes('Fri 3A'),        %w[11 11 10 7]
        Eq @db.classes('Sem1 Fri 3A'),   %w[11 11 10 7]
      end
      D "Non school days (weekends, holidays, public holidays, staff days, speech day)" do
        Eq @db.classes('Sat'),           nil   # weekend
        Eq @db.classes('Sun'),           nil   # weekend
        Eq @db.classes('11 Jul'),        nil   # holiday
        Eq @db.classes('25 Apr'),        nil   # public holiday
        Eq @db.classes('30 Jan'),        nil   # staff day
        Eq @db.classes('Sem1 1A Mon'),   nil   # same as above
        Eq @db.classes('5 Dec 2012'),    nil   # Speech Day
        Eq @db.classes('5 Dec'),         nil   # Speech Day
          # '5 Dec' is problematic, because Chronic looks to the past, not the
          # future, to make things like 'Tuesday' work as intended. I've worked
          # around it in SchoolOrNaturalDateParser.
        E(SR::SRError) { @db.classes('5 Dec 2011') }
      end
    end
    D "It can retrive timetabled lessons for any date" do
      D "Wed 3A Sem1 -- no obstacles" do
        sd = @db.schoolday("Wed 3A Sem1")
        tl = @db.timetabled_lessons(sd)  # -> [ TimetabledLesson ]
        Eq tl[0].schoolday,   sd
        Eq tl[0].class_label, '11'
        Eq tl[0].period,      1
        Eq tl[0].obstacle,    nil
        F  tl[0].obstacle?
        Eq tl[1].schoolday,   sd
        Eq tl[1].class_label, '12'
        Eq tl[1].period,      2
        Eq tl[1].obstacle,    nil
        F  tl[1].obstacle?
        Eq tl[2].schoolday,   sd
        Eq tl[2].class_label, '7'
        Eq tl[2].period,      4
        Eq tl[2].obstacle,    nil
        F  tl[2].obstacle?
        Eq tl[3].schoolday,   sd
        Eq tl[3].class_label, '10'
        Eq tl[3].period,      5
        Eq tl[3].obstacle,    nil
        F  tl[3].obstacle?
      end
      D "Thu 14B Sem1 -- can't make before-school Year 10 lesson" do
        sd = @db.schoolday("Thu 14B Sem1")
        tl = @db.timetabled_lessons(sd)
        Eq tl[0].schoolday,   sd
        Eq tl[0].class_label, '10'
        Eq tl[0].period,      0
        T  tl[0].obstacle?
        Eq tl[0].obstacle.reason, "I can't make early lesson"
        Eq tl[0].to_s, "TimetabledLesson: Sem1 Thu 14B; 10(0); I can't make early lesson"
        Eq tl[1].to_s, "TimetabledLesson: Sem1 Thu 14B; 10(1); nil"
        Eq tl[2].to_s, "TimetabledLesson: Sem1 Thu 14B; 7(2); nil"
        Eq tl[3].to_s, "TimetabledLesson: Sem1 Thu 14B; 11(5); nil"
      end
      D "9A Mon --> 9A Thu: Year 7 exams" do
        D "Monday" do
          sd = @db.schoolday("9A Mon Sem1")
          tl = @db.timetabled_lessons(sd)
          Eq tl[0].to_s, "TimetabledLesson: Sem1 Mon 9A; 10(0); nil"
          Eq tl[1].to_s, "TimetabledLesson: Sem1 Mon 9A; 11(1); nil"
          Eq tl[2].to_s, "TimetabledLesson: Sem1 Mon 9A; 7(4); Exams"
          Eq tl[3].to_s, "TimetabledLesson: Sem1 Mon 9A; 12(5); nil"
        end
        D "Tuesday" do
          sd = @db.schoolday("9A Tue Sem1")
          tl = @db.timetabled_lessons(sd)
          Eq tl[0].to_s, "TimetabledLesson: Sem1 Tue 9A; 10(2); nil"
          Eq tl[1].to_s, "TimetabledLesson: Sem1 Tue 9A; 12(3); nil"
          Eq tl[2].to_s, "TimetabledLesson: Sem1 Tue 9A; 11(4); nil"
          Eq tl[3].to_s, "TimetabledLesson: Sem1 Tue 9A; 7(5); Exams"
        end
        D "Wednesday" do
          sd = @db.schoolday("9A Wed Sem1")
          tl = @db.timetabled_lessons(sd)
          Eq tl[0].to_s, "TimetabledLesson: Sem1 Wed 9A; 11(1); nil"
          Eq tl[1].to_s, "TimetabledLesson: Sem1 Wed 9A; 12(2); nil"
          Eq tl[2].to_s, "TimetabledLesson: Sem1 Wed 9A; 7(4); Exams"
          Eq tl[3].to_s, "TimetabledLesson: Sem1 Wed 9A; 10(5); nil"
        end
        D "Thursday" do
          sd = @db.schoolday("9A Thu Sem1")
          tl = @db.timetabled_lessons(sd)
          Eq tl[0].to_s, "TimetabledLesson: Sem1 Thu 9A; 10(0); nil"
          Eq tl[1].to_s, "TimetabledLesson: Sem1 Thu 9A; 10(1); nil"
          Eq tl[2].to_s, "TimetabledLesson: Sem1 Thu 9A; 7(2); Exams"
          Eq tl[3].to_s, "TimetabledLesson: Sem1 Thu 9A; 12(5); nil"
        end
        D "Friday (out of obstacle range)" do
          sd = @db.schoolday("9A Fri Sem1")
          tl = @db.timetabled_lessons(sd)
          Eq tl[0].to_s, "TimetabledLesson: Sem1 Fri 9A; 11(1); nil"
          Eq tl[1].to_s, "TimetabledLesson: Sem1 Fri 9A; 11(2); nil"
          Eq tl[2].to_s, "TimetabledLesson: Sem1 Fri 9A; 10(4); nil"
          Eq tl[3].to_s, "TimetabledLesson: Sem1 Fri 9A; 7(5); nil"
        end
      end
      D "Sem2 8B Tue: two lessons missed for prefect induction" do
          sd = @db.schoolday("Sem2 8B Tue")
          tl = @db.timetabled_lessons(sd)
          Eq tl[0].to_s, "TimetabledLesson: Sem2 Tue 8B; 10(2); Prefect induction"
          Eq tl[1].to_s, "TimetabledLesson: Sem2 Tue 8B; 12(3); Prefect induction"
          Eq tl[2].to_s, "TimetabledLesson: Sem2 Tue 8B; 12(4); nil"
          Eq tl[3].to_s, "TimetabledLesson: Sem2 Tue 8B; 7(6); nil"
      end
    end
  end
end
