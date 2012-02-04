# Calendar#schoolday

This piece of development will focus on the very important method
`Calendar#schoolday(string)`. This will be the real interface for other classes
to determine whether a given day is a schoolday, and what day/date it is.

The string argument can be a variety of things, like:

* 4 Mar
* 12B Tue
* Friday
* Fri
* Tue 12B
* Sem2 12B Tue (or different order)
* 2012-06-15
* today/yesterday/tomorrow
* 3 days ago

I started implementing this method a while ago, then realised I needed Term and
Semester classes, so implemented and tested those. With those classes complete,
finishing this shouldn't be too hard.  The idea, partially implemented, is:

* Get Chronic to have a go at the string and see if it can make a Date.
    * That takes care of '4 Mar', 'today/yesterday/tomorrow', '3 days ago' and
      of course '2012-06-15'.
    * Given a Date object, we can use `Semester#week_and_day(date) -> [4,2]`
      and then construct a SchoolDay for potential return.
* If that fails, extract the nuggets like 'Sem2', '12B' and 'Tue' from the
  string and work it out that way.
    * Given the desired semester (which can be implied from the current date),
      week and day, we can call `Semester#date(week: 7, day: 3) -> Date` and
      construct a SchoolDay object for potential return.
* If _that_ fails, we raise an error.
* Given a SchoolDay object, we can now check to see if it's a public holiday,
  staff day or Speech Day.  I'd like to return something that indicates the
  reason that it's not a school day, but haven't thought enough about that yet.

The return value is a SchoolDay object, which enables the caller to find out all
sorts of things: date, week, day, semester, day in cycle, and more.  The day in
cycle (1..10) enables the lessons for the day to be retrieved through Timetable.

I've decided to change SchoolDay to be based on the semester, not on the term.
It doesn't change the API except for #initialize.

    SchoolDay.new(date, term, day)      # old
    SchoolDay.new(date, semester, day)  # new

Actually, I don't think that can work. If all the SchoolDay object knows it the
semester, it can't work out the term (it is not a smart object and has no access
to the calendar). But given a term it can determine the semester. So the old way
stays, even though it may make Calendar#schoolday more difficult to implement.

_Actually_, I've decided it will be that way after all. A school date is
fundamentally a semester and a week, so the term is irrelevant in this context.
I've changed the definition of SchoolDay#term to raise an error. I don't think
that error will ever be raised because that method shouldn't need to be called.

I've implemented Calendar#schoolday but have still not ironed everything out
despite lots of testing and fiddling. It appears I'm having trouble with the
Semester objects being created. 

    def schoolday(string)
      date = SchoolOrNaturalDateParser.new(self).parse(string)
      if date and school_day?(date)
        debug "Calendar#schoolday('#{string}') -- date == #{date.to_s}"
        semester = @semesters.find { |s| s.include? date }

The last line there is failing to find a semester that includes the date, but
that's ridiculous because the date is a confirmed school date.  On inspecting
the first semester object, I noticed:


    #<SchoolRecord::Calendar::Semester:0x000001008590c0
     @number=
      [#<SchoolRecord::Calendar::Term:0x00000100854390
        @finish=#<Date: 2012-04-05 ((2456023j,0s,0n),+0s,2299161j)>,
        @monday_of_first_week=#<Date: 2012-01-30 ((2455957j,0s,0n),+0s,2299161j)>,
        @number=1,
        @start=#<Date: 2012-01-30 ((2455957j,0s,0n),+0s,2299161j)>,
        @weeks=1..10>,
       #<SchoolRecord::Calendar::Term:0x00000100852e50
        @finish=#<Date: 2012-06-22 ((2456101j,0s,0n),+0s,2299161j)>,
        @monday_of_first_week=#<Date: 2012-04-23 ((2456041j,0s,0n),+0s,2299161j)>,
        @number=2,
        @start=#<Date: 2012-04-26 ((2456044j,0s,0n),+0s,2299161j)>,
        @weeks=1..9>],
     @number_of_weeks=19,
     @t1= ...

That `@number` is very fishy.  It should be the number 1 (for Semester 1), not
an array of terms.  How did it get like this?

The creation of the Semester objects is done like this:

    @semesters = [Semester.new(@terms[0..1], @terms[2..3])]

And now I can see the mistake.  It should be

    @semesters = [Semester.new(1, @terms[0..1]),
                  Semester.new(2, @terms[2..3])]

I can't believe I wrote that code and didn't notice the error on inspection.
I'll add some code to check the correctness of arguments.

> Aside: xEq doesn't appear to be working correctly in Whitestone. It is
> supposed to not run that test, but it is running it.

OK, I've finally gotten all Calendar tests passing. The following line was
causing all sorts of errors.

    SR::DO::SchoolDay.new(date, semester, week)            # incorrect
    SR::DO::SchoolDay.new(date, semester.number, week)     # correct

Goes to show I should be sleeping instead of coding.

Committing and going to bed.
