
def L(*args)
  args << nil if args.size == 2
  SR::DO::Lesson.new(*args)
end

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
        - dates: 9A Mon --> 9A Thu
          class: 7
          reason: Exams
        - date: Thu 14B
          class: 10(0)
          reason: I can't make early lesson
      Sem2:
        - date: 1A Fri
          class: 12
          reason: Yr12 Study Day
        - date: 9A-Mon
          class: 12, 11(4)
          reason: Prefect induction
    }.gsub(/^      /, '')
    @obstacles = SR::Obstacle.from_yaml(@cal, str)
  }
  D "Creates an array of Obstacles" do
    Ko @obstacles, Array
    Eq @obstacles.size, 6
    T  @obstacles.all? { |x| SR::Obstacle === x }
  end
  D "First one: 5 Jun" do
    # - date: 5 June
    #   classes: 7, 10
    #   reason: Moderator's assembly
    ob = @obstacles.shift
    sd_5_jun = @cal.schoolday('2012-06-05')
    sd_6_jun = @cal.schoolday('2012-06-06')
    # todo: test ob.dates
    # Eq ob.class_labels, ['7', '10']    -- no longer applicable?
    Eq ob.reason, "Moderator's assembly"
    T  ob.match?( L(sd_5_jun, '7') )
    T  ob.match?( L(sd_5_jun, '10') )
    F  ob.match?( L(sd_5_jun, '11') )
    F  ob.match?( L(sd_5_jun, '12') )
    F  ob.match?( L(sd_6_jun, '7') )
    F  ob.match?( L(sd_6_jun, '10') )
    F  ob.match?( L(sd_6_jun, '11') )
    F  ob.match?( L(sd_6_jun, '12') )
  end
  D "Second one: 12B-Wed" do
    # - date: 12B-Wed
    #   class: 7
    #   reason: Geography excursion
    ob = @obstacles.shift
    sd_12b_wed = @cal.schoolday("Sem1 12B Wed")
    sd_12b_thu = @cal.schoolday("Sem1 12B Thu")
    # todo: test ob.dates
    # Eq ob.class_labels, ['7']      -- no longer applicable?
    Eq ob.reason, "Geography excursion"
    T  ob.match?( L(sd_12b_wed, '7') )
    F  ob.match?( L(sd_12b_wed, '10') )
    F  ob.match?( L(sd_12b_wed, '11') )
    F  ob.match?( L(sd_12b_wed, '12') )
    F  ob.match?( L(sd_12b_thu, '7') )
    F  ob.match?( L(sd_12b_thu, '10') )
  end
  D "Third one: 9A Mon --> 9A Thu" do
    # - dates: 9A Mon --> 9A Thu
    #   class: 7
    #   reason: Exams
    ob = @obstacles.shift
    sd_9a_mon = @cal.schoolday("Sem1 9A Mon")
    sd_9a_tue = @cal.schoolday("Sem1 9A Tue")
    sd_9a_wed = @cal.schoolday("Sem1 9A Wed")
    sd_9a_thu = @cal.schoolday("Sem1 9A Thu")
    sd_9a_fri = @cal.schoolday("Sem1 9A Fri")
    Eq ob.dates, ( sd_9a_mon.date .. sd_9a_thu.date )
    # Eq ob.class_labels, ['7']      -- no longer applicable?
    Eq ob.reason, "Exams"
    T  ob.match?( L(sd_9a_mon, '7') )
    T  ob.match?( L(sd_9a_tue, '7') )
    T  ob.match?( L(sd_9a_wed, '7') )
    T  ob.match?( L(sd_9a_thu, '7') )
    F  ob.match?( L(sd_9a_fri, '7') )
    F  ob.match?( L(sd_9a_mon, '11') )
    F  ob.match?( L(sd_9a_tue, '11') )
    F  ob.match?( L(sd_9a_wed, '11') )
    F  ob.match?( L(sd_9a_thu, '11') )
    F  ob.match?( L(sd_9a_fri, '11') )
  end
  D "Fourth one: Thu 14B 10(0) -- note specific period" do
    # - date: Thu 14B
    #   class: 10(0)
    #   reason: I can't make early lesson
    ob = @obstacles.shift
    sd_14b_thu = @cal.schoolday("Sem1 Thu 14B")
    sd_14b_fri = @cal.schoolday("Sem1 Fri 14B")
    Eq ob.reason, "I can't make early lesson"
    T  ob.match?( L(sd_14b_thu, '10', 0) )
    F  ob.match?( L(sd_14b_thu, '10', 1) )
    F  ob.match?( L(sd_14b_thu, '7',  2) )
    F  ob.match?( L(sd_14b_fri, '10', 0) )
  end
  D "Fifth one: 1A Fri (Sem 2)" do
    # Sem2:
    #   - date: 1A Fri
    #     class: 12
    #     reason: Yr12 Study Day
    ob = @obstacles.shift
    sd_1a_fri = @cal.schoolday("Sem2 1A Fri")
    Eq ob.dates, (sd_1a_fri.date .. sd_1a_fri.date)
    Eq ob.reason, "Yr12 Study Day"
    T  ob.match?( L(sd_1a_fri, '12', 4))
  end
  D "Sixth one: 9A-Mon: 12, 11(4)  -- complex class parsing" do
    #   - date: 9A-Mon
    #     class: 12, 11(4)
    #     reason: Prefect induction
    ob = @obstacles.shift
    sd_9a_mon = @cal.schoolday("Sem2 9A Mon")
    Eq ob.dates, (sd_9a_mon.date .. sd_9a_mon.date)
    Eq ob.reason, "Prefect induction"
    T  ob.match?( L(sd_9a_mon, '12', 1) )
    T  ob.match?( L(sd_9a_mon, '12', 2) )
    T  ob.match?( L(sd_9a_mon, '11', 4) )
    F  ob.match?( L(sd_9a_mon, '11', 5) )
  end

end  # Obstacle.from_yaml
