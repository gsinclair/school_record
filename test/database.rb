
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
  end
end
