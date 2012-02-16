
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
    Eq timetable.class_labels_only(sd01), ['10','11','7','12']
    Eq timetable.class_labels_only(sd02), ['10','12','11','7']
    Eq timetable.class_labels_only(sd03), ['11','12','7','10']
    Eq timetable.class_labels_only(sd04), ['10','10','7','12']
    Eq timetable.class_labels_only(sd05), ['11','11','10','7']
    Eq timetable.class_labels_only(sd06), ['10','7','12','11']
    Eq timetable.class_labels_only(sd07), ['10','12','12','7']
    Eq timetable.class_labels_only(sd08), ['12','11','10','7']
    Eq timetable.class_labels_only(sd09), ['10','10','7','11']
    Eq timetable.class_labels_only(sd10), ['10','7','12','11']
    Eq timetable.classes(sd01), [ ['10',0], ['11',1], ['7',4], ['12',5] ]
    Eq timetable.classes(sd04), [ ['10',0], ['10',1], ['7',2], ['12',5] ]
    Eq timetable.classes(sd05), [ ['11',1], ['11',2], ['10',4], ['7',5] ]
    Eq timetable.classes(sd07), [ ['10',2], ['12',3], ['12',4], ['7',6] ]
  end
end
