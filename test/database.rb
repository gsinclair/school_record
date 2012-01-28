
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
      student = @db.resolve_student!('11', 'ISmy')
      Ko student, SR::DO::Student
      Eq student.fullname, "Isabella Smythe"
    end
    D "It can access the saved notes ('notes' method)" do
      notes = @db.notes('9')
      Ko notes, Array
      Eq notes.size, 1
      Eq notes.first.student.fullname, "Mikaela Achie"
      Eq notes.first.text,             "Missing equipment"
      notes = @db.notes('11')
      Eq notes.size, 2
      Eq notes.first.student.fullname, "Isabella Henderson"
      Eq notes.first.text,             "Assignment not submitted"
      Eq notes.last.student.fullname,  "Anna Burke"
      Eq notes.last.text,              "Good work on board"
      notes = @db.notes('11', 'ABur')
      Eq notes.size, 1
      Eq notes.first.student.fullname,  "Anna Burke"
      Eq notes.first.text,              "Good work on board"
    end
  end
end
