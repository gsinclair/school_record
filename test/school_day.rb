
D "SchoolDay" do
  D "test 1" do
    sd = SR::DO::SchoolDay.new(Date.new(2012,2,21), 1, 4)
    Eq sd.date, Date.new(2012, 2, 21)
    Eq sd.semester, 1
    Eq sd.term,     1
    Eq sd.week,     4
    Eq sd.weekstr, '4B'
    Eq sd.day,     'Tue'
    Eq sd.month,   'Feb'
    Eq sd.year,    2012
    Eq sd.a_or_b,  'B'
    Eq sd.day_of_cycle, 7
    Eq sd.to_s,     'Tue 4B (21 Feb)'
    Eq sd.sem_date, 'Tue 4B'
    Eq sd.sem_date(:semester), 'Sem1 Tue 4B'
    Eq sd.sem_date(true),      'Sem1 Tue 4B'
  end

  D "test 2" do
    sd = SR::DO::SchoolDay.new(Date.new(2012,11,9), 4, 15)
    Eq sd.date, Date.new(2012, 11, 9)
    Eq sd.semester, 2
    Eq sd.term,     4
    Eq sd.week,     15
    Eq sd.weekstr, '15A'
    Eq sd.day,     'Fri'
    Eq sd.month,   'Nov'
    Eq sd.year,    2012
    Eq sd.a_or_b,  'A'
    Eq sd.day_of_cycle, 5
    Eq sd.to_s,     'Fri 15A (9 Nov)'
    Eq sd.sem_date, 'Fri 15A'
    Eq sd.sem_date(:semester), 'Sem2 Fri 15A'
    Eq sd.sem_date(true),      'Sem2 Fri 15A'
  end
end
