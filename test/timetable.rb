
D "Timetable" do
  D "Load correct config and return correct values" do
    db = SR::Database.test
    @timetable = db.timetable
    Eq @timetable.lessons_export_string( 1), "10(0), 11(1), 7(4), 12(5)"
    Eq @timetable.lessons_export_string( 2), "10(2), 12(3), 11(4), 7(5)" 
    Eq @timetable.lessons_export_string( 3), "11(1), 12(2), 7(4), 10(5)"
    Eq @timetable.lessons_export_string( 4), "10(0), 10(1), 7(2), 12(5)"
    Eq @timetable.lessons_export_string( 5), "11(1), 11(2), 10(4), 7(5)"
    Eq @timetable.lessons_export_string( 6), "10(0), 7(1), 12(3), 11(5)"
    Eq @timetable.lessons_export_string( 7), "10(2), 12(3), 12(4), 7(6)"
    Eq @timetable.lessons_export_string( 8), "12(1), 11(2), 10(5), 7(6)"
    Eq @timetable.lessons_export_string( 9), "10(0), 10(1), 7(2), 11(5)"
    Eq @timetable.lessons_export_string(10), "10(3), 7(4), 12(5), 11(6)"
    D "Error if given invalid day_of_cycle" do
      E(SR::SRInternalError) { @timetable.lessons_export_string(13) }
    end
  end
end
