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

## Testing Database#timetabled\_lessons

Amazingly, a method I assumed existed, doesn't: Database#schoolday(str).
Nevermind:

    def schoolday(date_string)
      @calendar.schoolday(date_string)
    end

That's the first test run out of the way. The second one exposed another
problem, solved by:

      timetable.lessons(schoolday.day_of_cycle).map { |lesson|
                                 ^^^^^^^^^^^^^

Then another, solved by:

        SR::TimetabledLesson.new(schoolday, lesson, obstacle)
        ^^^^

and

    require 'school_record/timetabled_lesson'

And voila:

      +----- Report ---------------------------------------------------------------+
      |                                                                            |
      |  Database                                                           -      |
      |    Can be loaded (test database)                                    PASS   |
      |    When it's loaded                                                 -      |
      |      It can resolve student names                                   PASS   |
      |      It can resolve! student names                                  PASS   |
      |      It can access the saved notes ('notes' method)                 PASS   |
      |      It can retrive timetabled lessons for any date                 -      |
      |        Wed 3A Sem1 -- no obstacles                                  PASS   |
      |                                                                            |
      +----------------------------------------------------------------------------+

     ================================================================================
      PASS     #pass: 5     #fail: 0     #error: 0     assertions: 40    time: 0.299
     ================================================================================

One test down, which by the way looks like:

    D "It can retrive timetabled lessons for any date" do
      D "Wed 3A Sem1 -- no obstacles" do
        sd = @db.schoolday("Wed 3A Sem1")
        tl = @db.timetabled_lessons(sd)  # -> [ TimetabledLesson ]
        Eq tl[0].schoolday,   sd
        Eq tl[0].class_label, '11'
        Eq tl[0].period,      1
        Eq tl[0].obstacle,    nil
        F  tl[0].obstacle?
        Eq tl[1].schoolday,   sd
        Eq tl[1].class_label, '12'
        # ...

So I haven't tested any obstacled lessons yet. ... And now:

    |      It can retrive timetabled lessons for any date                 -      |
    |        Wed 3A Sem1 -- no obstacles                                  PASS   |
    |        Thu 14B Sem1 -- can't make before-school Year 10 lesson      PASS   |

In testing obstacled lessons, it helped to implement `Obstacle#to_s(:brief)` and
`TimetabledLesson#to_s`, enabling lines like:

    Eq ob.to_s(:brief), "Obstacle: 2012-07-20; 12; Yr12 Study Day"
    Eq tl.to_s, "TimetabledLesson: Sem1 8B Fri; 7(1); Moderator's assembly"

I now have a series of tests:

      D "9A Mon --> 9A Thu: Year 7 exams" do
        D "Monday" do
          sd = @db.schoolday("9A Mon Sem1")
          tl = @db.timetabled_lessons(sd)
          Eq tl[0].to_s, "TimetabledLesson: Sem1 Mon 9A; 10(0); nil"
          Eq tl[1].to_s, "TimetabledLesson: Sem1 Mon 9A; 11(1); nil"
          Eq tl[2].to_s, "TimetabledLesson: Sem1 Mon 9A; 7(4); Exams"
          Eq tl[3].to_s, "TimetabledLesson: Sem1 Mon 9A; 12(5); nil"
        end
        # Tuesday, Wednesday, Thursday, Friday ...

All of them pass.

**Failing test** I rigged a special test to see if it could handle two
period-specific obstacles. Here is the relevant config:

    Sem2:
      - date: 10B-Tue
        class: 12(3), 10(2)
        reason: Prefect induction

Here is the test code:

    D "Sem2 10B Tue: two lessons missed for prefect induction" do
        sd = @db.schoolday("Sem2 10B Tue")
        tl = @db.timetabled_lessons(sd)
        Eq tl[0].to_s, "TimetabledLesson: Sem2 Tue 10B; 10(2); Prefect induction"
        Eq tl[0].to_s, "TimetabledLesson: Sem2 Tue 10B; 12(3); nil"
        Eq tl[0].to_s, "TimetabledLesson: Sem2 Tue 10B; 12(4); Prefect induction"
        Eq tl[0].to_s, "TimetabledLesson: Sem2 Tue 10B; 7(6); nil"
    end

And surprisingly, it's failing:

    ERROR: Can be loaded (test database)
        test/database.rb
           2 D "Database" do
           3   D "Can be loaded (test database)" do
        => 4     db = SR::Database.test
           5     Ko db, SR::Database
           6   end
      Class:   NoMethodError
      Message: undefined method `date' for nil:NilClass
      Backtrace
        ./lib/school_record/obstacle.rb:153:in `create_obstacle'
        ./lib/school_record/obstacle.rb:137:in `block in create_obstacles'
        ./lib/school_record/obstacle.rb:137:in `map'
        ./lib/school_record/obstacle.rb:137:in `create_obstacles'
        ./lib/school_record/obstacle.rb:126:in `obstacles'
        ./lib/school_record/obstacle.rb:57:in `from_yaml'

That config is causing it to fail to load!  I need to go back and test Obstacle
directly with that config.  That's tomorrow's job.

Lots of files modified, but I don't want to commit right now because of the
failing state.

**(22 Feb 2012)**

The problem was caused by a date (Sem2 10B Tue) being not a school day. I
improved the situation by raising an appropriate error message in that
situation. Tests are passing now.

I declare Database#timetabled\_lesson working and am committing the code.
