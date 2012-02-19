
D "DateString" do
  D "13 Feb" do
    ds = SR::DateString.new(" \t\r\n 13 Feb  ")
    F ds.iso_date?
    T ds.contains?(:mday, :month)
    T ds.contains?(:month)
    T ds.contains?(:mday)
    T ds.contains?()
    T ds.contains_only?(:mday, :month)
    F ds.contains_only?(:mday)
    F ds.contains_only?(:month)
    F ds.contains?(:iso_date)
    F ds.contains?(:semester)
    F ds.contains?(:sem_week)
    F ds.contains?(:year)
    F ds.contains?(:unknown)
    Eq ds.to_s, "13 Feb"
    T ds.day_month_style?
    F ds.semester_style?
  end

  D "Mon-13A" do
    ds = SR::DateString.new("Mon-13A")
    F ds.iso_date?
    T ds.contains?(:wday)
    T ds.contains?(:sem_week)
    T ds.contains_only?(:wday, :sem_week)
    Eq ds.to_s, "Mon-13A"
    T ds.semester_style?
    F ds.day_month_style?
  end

  D "Sem2 8B Thu" do
    ds = SR::DateString.new("Sem2 8B Thu")
    F ds.iso_date?
    T ds.contains_only?(:semester, :sem_week, :wday)
    T ds.semester_style?
    F ds.day_month_style?
  end

  D "2012-08-31" do
    ds = SR::DateString.new("2012-08-31")
    T ds.iso_date?
    T ds.contains_only?(:iso_date)
  end
end
