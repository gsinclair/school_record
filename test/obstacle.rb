
D "Obstacle.from_yaml" do
  D.<< { @cal = SR::Database.test.calendar }
  D.<< {
    str = %{
      Sem1:
        - date: 5 June
          classes: 7, 10
          reason: Moderator's assembly
        - date: 12B-Wed
          class: 7
          reason: Geography excursion
        - dates: ["9A-Mon", "9A-Thu"]
          class: 7
          reason: Exams
        - date: 3A-Mon
          class: 11(4)
          reason: Maths assembly
      Sem2:
        - date: 1A Fri
          class: 12
          reason: Yr12 Study Day
        - date: Thu 14B
          class: 10(0)
          reason: I can't make early lesson
    }.gsub(/^      /, '')
    @obstacles = SR::Obstacle.from_yaml(@cal, str)
  }
  D "Creates an array of Obstacles" do
    Ko @obstacles, Array
    Eq @obstacles.size, 6
    T  @obstacles.all? { |x| SR::Obstacle === x }
  end
  D "First one: 5 Jun" do
    ob = @obstacles.shift
    sd_5_jun = @cal.schoolday('2012-06-05')
    sd_6_jun = @cal.schoolday('2012-06-06')
    Eq ob.schooldays.first, sd_5_jun
    Eq ob.class_labels, ['7', '10']
    Eq ob.reason, "Moderator's assembly"
    Eq ob.period, nil
    T  ob.match?(sd_5_jun, '7')
    T  ob.match?(sd_5_jun, '10')
    F  ob.match?(sd_5_jun, '11')
    F  ob.match?(sd_5_jun, '12')
    F  ob.match?(sd_6_jun, '7')
    F  ob.match?(sd_6_jun, '10')
    F  ob.match?(sd_6_jun, '11')
    F  ob.match?(sd_6_jun, '12')
  end
  D "Second one: 12B-Wed" do
    ob = @obstacles.shift
    sd_12b_wed = @cal.schoolday("Sem1 12B Wed")
    sd_12b_thu = @cal.schoolday("Sem1 12B Thu")
    Eq ob.schooldays.first, sd_12b_wed
    Eq ob.class_labels, ['7']
    Eq ob.reason, "Geography excursion"
    Eq ob.period, nil
    T  ob.match?(sd_12b_wed, '7')
    F  ob.match?(sd_12b_wed, '10')
    F  ob.match?(sd_12b_wed, '11')
    F  ob.match?(sd_12b_wed, '12')
    F  ob.match?(sd_12b_thu, '7')
    F  ob.match?(sd_12b_thu, '10')
  end
  D "Third one: 9A Monday to Thursday" do
    ob = @obstacles.shift
    sd_9a_mon = @cal.schoolday("Sem1 9A Mon")
    sd_9a_tue = @cal.schoolday("Sem1 9A Tue")
    sd_9a_wed = @cal.schoolday("Sem1 9A Wed")
    sd_9a_thu = @cal.schoolday("Sem1 9A Thu")
    sd_9a_fri = @cal.schoolday("Sem1 9A Fri")
    Eq ob.schooldays.first, sd_9a_mon
    Eq ob.schooldays.last,  sd_9a_thu
    Eq ob.class_labels, ['7']
    Eq ob.reason, "Exams"
    Eq ob.period, nil
    T  ob.match?(sd_9a_mon, '7')
    T  ob.match?(sd_9a_tue, '7')
    T  ob.match?(sd_9a_wed, '7')
    T  ob.match?(sd_9a_thu, '7')
    F  ob.match?(sd_9a_fri, '7')
    F  ob.match?(sd_9a_mon, '11')
    F  ob.match?(sd_9a_tue, '11')
    F  ob.match?(sd_9a_wed, '11')
    F  ob.match?(sd_9a_thu, '11')
    F  ob.match?(sd_9a_fri, '11')
  end
  D "Fourth one: 3A-Mon pd4" do
    ob = @obstacles.shift
    sd_3a_mon = @cal.schoolday("Sem1 3A-Mon")
    sd_3a_tue = @cal.schoolday("Sem1 3A-Tue")
    Eq ob.schooldays.first, sd_3a_mon
    Eq ob.class_labels, ['11']
    Eq ob.period, 4
    Eq ob.reason, "Maths assembly"
    #T  ob.match?(sd_3a_mon, '11')
  end

end  # Obstacle.from_yaml
