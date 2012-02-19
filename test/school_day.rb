
D "SchoolDay" do
  D "2012-02-21, Semester 1, Week 4" do
    sd = SR::DO::SchoolDay.new(Date.new(2012,2,21), 1, 4)
    Eq sd.date, Date.new(2012, 2, 21)
    Eq sd.semester, 1
    #Eq sd.term,     1
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

  D "2012-11-00, Semester 2, Week 15" do
    sd = SR::DO::SchoolDay.new(Date.new(2012,11,9), 2, 15)
    Eq sd.date, Date.new(2012, 11, 9)
    Eq sd.semester, 2
    #Eq sd.term,     4
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

  D "Equality" do
    sd1 = SR::DO::SchoolDay.new(Date.new(2012,11,9), 2, 15)
    sd2 = SR::DO::SchoolDay.new(Date.new(2012,11,9), 2, 15)
    sd3 = SR::DO::SchoolDay.new(Date.new(2012,11,8), 2, 15)
    Eq  sd1, sd2
    Eq  sd2, sd1
    Eq! sd2, sd3
    Eq! sd3, sd2
  end

  D "Comparison" do
    sd1 = SR::DO::SchoolDay.new(Date.new(2012,2,20), 1, 4)
    sd2 = SR::DO::SchoolDay.new(Date.new(2012,2,21), 1, 4)
    sd3 = SR::DO::SchoolDay.new(Date.new(2012,2,22), 1, 4)
    T { sd1 < sd2 }
    T { sd2 < sd3 }
    T { sd2 > sd1 }
    T { sd3 > sd2 }
  end

  D "Error when given bad input" do
    E(SR::SRError) { SR::DO::SchoolDay.new(Date.new(2012,11,9), 3, 14)}
    E(SR::SRError) { SR::DO::SchoolDay.new(Date.new(2012,11,9), 1, 50)}
  end
end
