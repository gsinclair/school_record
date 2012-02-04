# Calendar (cont.)

The last entry finished with Calendar::Term implemented and tested and Calendar
itself in progress.  I'm now working on Calendar::Semester, which aggregates two
terms and implements many of the same methods.

  class Semester
    number                    # 1..2
    number_of_weeks           # 19 or 20 (most likely)
    include?(date)
    date(week: 15, day: 3)    # -> Date
    week_and_day(date)        # -> [week, day]

All now implemented. It's pretty simple: all the real work is done by the Term
objects. Now I just need to test it.

(31 Jan) Second day back at school and really tired, so not spending much time
on this. I implemented some Semester tests and exposed a bug. More tests on Term
resulted and both classes are looking good. More tests to be done on Semester,
though.

When that's done, I can implement Lessons, or Database#lessons\_for\_date, or
however I want to do it. Still mulling over options for organising that future
code.

(4 Feb) Calendar::Semester is now tested pretty well. Another bug was found and
fixed. Commit time, and I'll look at Calendar#schoolday next.
