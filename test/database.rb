
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
    D "It can look up the classes for any date" do
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
  end
end
