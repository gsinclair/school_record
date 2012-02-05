
D "Timetable" do
  D "Load correct config and return correct values" do
    db = SR::Database.test
    timetable = db.timetable
    date = Date.new(2012, 2, 13)   # Mon 13 Feb 2012
    sd01 = SR::DO::SchoolDay.new(date + 0,  1, 3)
    sd02 = SR::DO::SchoolDay.new(date + 1,  1, 3)
    sd03 = SR::DO::SchoolDay.new(date + 2,  1, 3)
    sd04 = SR::DO::SchoolDay.new(date + 3,  1, 3)
    sd05 = SR::DO::SchoolDay.new(date + 4,  1, 3)
    sd06 = SR::DO::SchoolDay.new(date + 7,  1, 4)
    sd07 = SR::DO::SchoolDay.new(date + 8,  1, 4)
    sd08 = SR::DO::SchoolDay.new(date + 9,  1, 4)
    sd09 = SR::DO::SchoolDay.new(date + 10, 1, 4)
    sd10 = SR::DO::SchoolDay.new(date + 11, 1, 4)
    Eq timetable.classes(sd01), ['10','11','7','12']
    Eq timetable.classes(sd02), ['10','12','11','7']
    Eq timetable.classes(sd03), ['11','12','7','10']
    Eq timetable.classes(sd04), ['10','10','7','12']
    Eq timetable.classes(sd05), ['11','11','10','7']
    Eq timetable.classes(sd06), ['10','7','12','11']
    Eq timetable.classes(sd07), ['10','12','12','7']
    Eq timetable.classes(sd08), ['12','11','10','7']
    Eq timetable.classes(sd09), ['10','10','7','11']
    Eq timetable.classes(sd10), ['10','7','12','11']
  end
end
