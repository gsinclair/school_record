# Database#timetabled\_lessons, at last

The need to obtain a sensibly-conceived list of the lessons timetabled for a
given day, along with information about obstacles (lessons that won't take
place because of an excursion or what have you) has driven all of the
development effort of the last week or more. Now that the foundations are in
place, though, I expect this to be easy.

Testing it will require a decent set of obstacles in the config file. Truth
be told, I don't even know which file they go in. Is it obstacles.yaml or
calendar.yaml? If it's not obstacles.yaml, it should be.

The operation of Database#timetabled\_lessons is as follows:

* For the given schoolday, get a list of lessons (Lesson objects) from the
  timetable.
* For each lesson, see if any of the obstacles stored in Database matches
  it.
* Create TimetabledLesson objects with the lesson info and any obstacle
  object attached.
* Return the list of TimetabledLesson objects.

I just remembered: Timetable#lessons should return Lesson objects that have
the schoolday filled in. (That was my idea a day or so ago.) Or should it?
Not really. The particular date is of no interest to the Timetable. In fact,
the query should be Timetable#lessons(day\_of\_cycle), not
Timetable#lessons(schoolday). I think I'll change that. So no: Timetable
will not infill the schoolday for you. This is more evidence that schoolday
does not belong in Lesson, only in TimetabledLesson.

Actions:

* Change Timetable#lessons() to take an integer (day of cycle), not
  schoolday.
* _Commit here_
* Remove 'schoolday' property from Lesson.
* _Commit here_
* Implement `timetabled_lessons`.
    * Needs obstacles loaded into database, which needs some obstacles in a
      file.

In working on database.rb, I realise how inconsistent some of the code is.
`load_class_lists` should be SchoolClass.from\_yaml, or something, and all
from\_yaml methods should agree on whether they take a Pathname or its
contents. (I think contents is good.) Some resources are loaded on
initialisation; some are loaded when first called. Cleaning all this up is a
day's work in itself.


