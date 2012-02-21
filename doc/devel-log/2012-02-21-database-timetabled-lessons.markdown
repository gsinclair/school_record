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

* [1] Change Timetable#lessons() to take an integer (day of cycle), not
  schoolday.
* _Commit here_
* [2] Remove 'schoolday' property from Lesson.
* _Commit here_
* [3] Implement `timetabled_lessons`.
    * [4] Needs obstacles loaded into database, which needs some obstacles in a
      file.

In working on database.rb, I realise how inconsistent some of the code is.
`load_class_lists` should be SchoolClass.from\_yaml, or something, and all
from\_yaml methods should agree on whether they take a Pathname or its
contents. (I think contents is good.) Some resources are loaded on
initialisation; some are loaded when first called. Cleaning all this up is a
day's work in itself.

I've done [1] and committed.  I accidentally started [3] before [2], and have
completed [4], so now I can work on [3] properly.

Here is the method of the hour in its entirety:

    def timetabled_lessons(schoolday)
      timetable.lessons(schoolday).map { |lesson|
        obstacle = @obstacles.find { |o| o.match?(schoolday, lesson) }
        TimetabledLesson.new(schoolday, lesson, obstacle)
      }

It requires the following changes:

* Dump schoolday from Lesson.
* Obstacle#match?(schoolday, lesson)
* TimetabledLesson.new(schoolday, lesson, obstacle)

These are changes for the better, and will result in a consistent approach
across the system.  And that is a job for tomorrow.

**(21 Feb 2012)**

* Removed schoolday from Lesson (definition and usage).
* TimetabledLesson.new(schoolday, lesson, obstacle).
* Obstacle#match?(schoolday, lesson)

After updating test/obstacle.rb to reflect the new match? method signature, all
tests pass.

OK, all actions [1] -- [4] are now complete. I have implemented
Database#timetabled\_lessons() and am confident it will work. All I have to do
now is write some tests.

I am committing now to provide a clean slate for diffs.
