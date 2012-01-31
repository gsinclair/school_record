
D "Calendar::Term" do
  D.< { @term = SR::Calendar::Term.new(2, d('2012-04-23'), d('2012-06-22')) }

  D "#number" do
    Eq @term.number, 2
  end

  D "#semester" do
    Eq @term.semester, 1
  end

  D "#include?" do
    F @term.include? d('2012-04-20')
    F @term.include? d('2012-04-21')
    F @term.include? d('2012-04-22')
    T @term.include? d('2012-04-23') # start of term
    T @term.include? d('2012-04-24')
    T @term.include? d('2012-04-25')

    T @term.include? d('2012-05-10') # middle of term
    
    T @term.include? d('2012-06-20')
    T @term.include? d('2012-06-21')
    T @term.include? d('2012-06-22') # end of term
    F @term.include? d('2012-06-23')
    F @term.include? d('2012-06-24')

    F @term.include? d('2012-10-19') # way off
    F @term.include? d('2011-04-25') # wrong year
    F @term.include? d('2013-04-25') # wrong year

    D "Returns false on weekends" do
      F @term.include? d('2012-05-05')  # Saturday
      F @term.include? d('2012-05-06')  # Sunday
    end
  end  # include?

  D "#number_of_weeks" do
    Eq @term.number_of_weeks, 9
  end

  D "#date(week: 7, day: 2) etc." do
    Eq @term.date(week: 7, day: 1), d('2012-06-04')
    Eq @term.date(week: 7, day: 2), d('2012-06-05')
    Eq @term.date(week: 7, day: 3), d('2012-06-06')
    Eq @term.date(week: 7, day: 4), d('2012-06-07')
    Eq @term.date(week: 7, day: 5), d('2012-06-08')
    Eq @term.date(week: 8, day: 1), d('2012-06-11')
    Eq @term.date(week: 8, day: 3), d('2012-06-13')
    Eq @term.date(week: 8, day: 5), d('2012-06-15')
    D "Raises error on invalid input" do
      E(SR::SRInternalError) { @term.date(week: -3, day: 4) }
      E(SR::SRInternalError) { @term.date(week: 11, day: 4) }
      E(SR::SRInternalError) { @term.date(week: 6,  day: 0) }
      E(SR::SRInternalError) { @term.date(week: 6,  day: 6) }
      E(SR::SRInternalError) { @term.date(week: 10, day: 2) }
    end
  end

  D "#week_and_day" do
    Eq @term.week_and_day('2012-04-23'), [1, 1]
    Eq @term.week_and_day('2012-04-24'), [1, 2]
    Eq @term.week_and_day('2012-04-25'), [1, 3]
    Eq @term.week_and_day('2012-04-26'), [1, 4]
    Eq @term.week_and_day('2012-04-27'), [1, 5]
    Eq @term.week_and_day('2012-04-30'), [2, 1]
    Eq @term.week_and_day('2012-05-01'), [2, 2]
    Eq @term.week_and_day('2012-05-04'), [2, 5]
    Eq @term.week_and_day('2012-05-23'), [5, 3]
    Eq @term.week_and_day('2012-06-21'), [9, 4]
    Eq @term.week_and_day('2012-06-22'), [9, 5]
    D "Returns nil if argument is not in term" do
      N @term.week_and_day('2012-04-19')
      N @term.week_and_day('2012-05-06')  # Sunday within term
      N @term.week_and_day('2012-10-13')
    end
  end

  D "Some tests on a pathological term" do
    # This term runs from Wed 5 Sep to Tue 25 Sep.
    @term = SR::Calendar::Term.new(3, d('2012-09-05'), d('2012-09-25'))
    Eq @term.number, 3
    Eq @term.number_of_weeks, 4
    F  @term.include? '2012-09-03'   # This is Monday of week 1 but it's excluded
    F  @term.include? '2012-09-04'   # Likewise Tuesday
    T  @term.include? '2012-09-05'   # First day of term
    T  @term.include? '2012-09-24'
    T  @term.include? '2012-09-25'   # Last day of term
    F  @term.include? '2012-09-26'   # Day after last day
    Eq @term.semester, 2
    Eq @term.date(week: 1, day: 1), nil   # Doesn't fall for Monday of first week
    Eq @term.date(week: 1, day: 2), nil   # Likewise Tuesday
    Eq @term.date(week: 1, day: 3), d('2012-09-05')
    Eq @term.date(week: 1, day: 4), d('2012-09-06')
    Eq @term.date(week: 3, day: 2), d('2012-09-18')
    Eq @term.date(week: 4, day: 2), d('2012-09-25')  # Last day
    Eq @term.date(week: 4, day: 3), nil
    Eq @term.week_and_day('2012-09-03'), nil
    Eq @term.week_and_day('2012-09-04'), nil
    Eq @term.week_and_day('2012-09-05'), [1,3]
    Eq @term.week_and_day('2012-09-06'), [1,4]
    Eq @term.week_and_day('2012-09-18'), [3,2]
    Eq @term.week_and_day('2012-09-25'), [4,2]
    Eq @term.week_and_day('2012-09-26'), nil
  end

  D "Error on stupid input" do
    D "Term outside 1..4" do
      E(SR::SRError) { SR::Calendar::Term.new(5, Date.today, Date.today) }
    end
    D "Start date after finish date" do
      E(SR::SRError) { SR::Calendar::Term.new(3, Date.today, Date.today - 25) }
    end
  end

end  # Calendar::Term

D "Calendar::Semester" do
  D.<< {
    t3 = SR::Calendar::Term.new(3, d('2012-07-16'), d('2012-09-20'))
    t4 = SR::Calendar::Term.new(4, d('2012-10-09'), d('2012-12-07'))
    @sem = SR::Calendar::Semester.new(2, [t3, t4])
  }
  D "#number" do
    Eq @sem.number, 2
  end
  D "#include?" do
    F @sem.include? '2012-07-15'  # Monday of week 1 is not included.
    T @sem.include? '2012-07-16'  # First day of term/semester.
    T @sem.include? '2012-08-03'
    F @sem.include? '2012-08-05'  # Weekend.
    F @sem.include? '2012-09-21'  # Last day is Thu; this is Fri.
    F @sem.include? '2012-09-26'  # This is in the holidays between the terms.
    T @sem.include? '2012-10-09'  # First day Term 4.
    T @sem.include? '2012-11-13'
    T @sem.include? '2012-12-07'  # Last day.
    F @sem.include? '2012-12-10'
  end
  D "#number_of_weeks" do
    Eq @sem.number_of_weeks, 19
  end
  D "#date(week: 7, day: 2) etc." do
    D "Handles the irregular start and end of term" do
      Eq @sem.date(week: 10, day: 5), nil
    end
  end
  D "#week_and_day" do
  end
end

xD "Calendar#schoolday" do
  D.<< {
    @cal = SR::Database.test.calendar
    @cal.today = Date.new(2012, 3, 7)  # Sem1 Wed 7A (7 Mar)
  }
  D.>> {
    @cal.reset_today
  }
  D "2012-02-16" do
    Eq @cal.schoolday("2012-02-16").sem_date(true), "Sem1 Thu 3A"
  end
  D "today" do
    Eq @cal.schoolday("today").sem_date(true), "Sem1 Wed 7A"
    Eq @cal.schoolday("today").date, Date.new(2012, 3, 7)
  end
  D "yesterday" do
    Eq @cal.schoolday("tomorrow").sem_date(true), "Sem1 Tue 7A"
    Eq @cal.schoolday("tomorrow").date, Date.new(2012, 3, 6)
  end
  D "12B Thu (and Thu 12B)" do
    Eq @cal.schoolday("12B Thu").sem_date(true), "Sem1 Thu 12B"
    Eq @cal.schoolday("12B Thu").date, Date.new(2012, 5, 3)
    Eq @cal.schoolday("Thu 12B").sem_date(true), "Sem1 Thu 12B"
    Eq @cal.schoolday("Thu 12B").date, Date.new(2012, 5, 3)
  end
  D "Thu 12B Sem2 and permutations" do
    Eq @cal.schoolday("Sem2 12B Thu").date, Date.new(2012, 10, 18)
    Eq @cal.schoolday("Sem2 Thu 12B").date, Date.new(2012, 10, 18)
    Eq @cal.schoolday("12B Thu Sem2").date, Date.new(2012, 10, 18)
    Eq @cal.schoolday("12B Sem2 Thu").date, Date.new(2012, 10, 18)
    Eq @cal.schoolday("Thu 12B Sem2").date, Date.new(2012, 10, 18)
    Eq @cal.schoolday("Thu Sem2 12B").date, Date.new(2012, 10, 18)
  end
  D "Error for incomplete or invalid input" do
    E(SR::SRError) { @cal.schoolday("12B") }
    E(SR::SRError) { @cal.schoolday("Sem1") }
    E(SR::SRError) { @cal.schoolday("xyz") }
  end
  D "nil for days that are not school days" do
    N @cal.schoolday("Sunday")
    N @cal.schoolday("2012-01-23")
  end
end
