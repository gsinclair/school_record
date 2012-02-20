# Using period information throughout the code

The previous development log, _Getting SQLite going_, opened a can of worms that
this one hopes to resolve. Here is the sequence:

* I retooled the Lesson class (soon to be called LessonDescription) to use
  SQLite instead of YAML as a data store.
* With YAML and per-day storage, it was always going to be possible to handle
  the occasions when I saw a particular class more than once in a day. With
  SQLite storage, that case required special attention. I resolved to store the
  period as part of the lesson. That opened the can of worms because none of the
  code (Timetable, Calendar, Obstacle [which was conceived but not yet written])
  had been written to handle period information.
* I changed Timetable to know what period each class was on. That was easy.
* Implementing Database#store\_lesson was still difficult to do cleanly, though.
  Quote:

> I don't like the style of code I'm writing here. It doesn't feel like the right
> design. I especially don't like the arrays that are passed around to include a
> class label and a period number. This should be an object, and I think I've
> found the right one:
> 
>     class TimetabledLesson
>       schoolday
>       class_label
>       period
>       obstacle?
>       obstacle
> 
> This provides information about, well, a timetabled lesson.  The "Lesson" class
> should probably change its name to "LessonDescription", because that's what it
> contains.
> 
>     sd = database.schoolday('Fri 3A')
>     database.timetabled_lessons(sd)
>       # -> [ TimetabledLesson, ... ]         (all classes for that day)
>     database.timetabled_lessons(sd, '12')
>       # -> [ TimetabledLesson, ... ]         (all Year 12 classes for that day)
> 
> The TimetabledLesson objects returned have obstacle information built into them.
> That should make it easier to store a lesson on a given day, and hopefully will
> mean I _don't_ need a class just for handling a day's worth of lessons. The
> array of TimetabledLesson objects will have enough smarts.
> 
> I guess the Database class could maintain a hash of the LessonDescription
> corresponding to each TimetabledLesson. There may be a use for that.
> 
> I feel like I'm finally making conceptual progress now. Here's what has to
> happen:
> 
> * Design, implement and test obstacles.
> * Implement and test TimetabledLesson (probably not much to test).
> * Implement and test Database#timetabled\_lessons (this is where the real tests
>   will be).
> * Implement Database#store\_lesson.

* So that plan emerged and I implemented and tested Obstacle. It was pretty easy
  except for when I once again ran into the "how to handle period information
  elegantly" conundrum.

Periods were introduced into the code, but in the gradual transition to using
them it means ad-hoc arrays combining classes and periods, and an extra
parameter here and there that may or may not be used.

To break the conceptual roadblock, I decided to introduce a Lesson value object.

> My current Lesson class is more properly named LessonDescription, as mentioned
> earlier. It is now time to make that change and introduce a value object called
> Lesson, which simply encapsulates a certain class having a lesson at a certain
> time (period) of a certain day.
> 
>     class Lesson
>       class_label
>       period
>       schoolday      # may be nil (?)
> 
> _[...comments on class TimetabledLesson...]_
> 
> So the plan is:
> 
> * Change Lesson to LessonDescription throughout the code.
> * Introduce Lesson, where schoolday may be nil.
> * Use this object wherever possible, and make all the relevant code
>   period-aware.
> * See what uses it has. Maybe I don't need "schoolday" at all (it can be a
>   separate parameter when needed); maybe I can use TimetabledLesson some of the
>   time.
> 
> Keep in mind: TimetabledLesson is important for the operation of the
> application. Lesson is just a value object that helps to generate the
> TimetabledLesson objects.

So there are two sets of plans above that I want to put into action in this
development log.

## Change Lesson to LessonDescription throughout the code

Done. I actually moved the lesson(description) code to the domain\_objects.rb
file, so it is `SR::DO::LessonDescription`, along with Student, SchoolDay, Note,
etc.

As part of this, I have freshened up the database loading code. I tried to move
it all to lib/school\_record.rb but couldn't get that to work, because as far as
I'm aware, DataMapper's setup is global, but I need just-in-time setup depending
on whether I'm using the dev, test or prd database.

Commit message: Lesson -> LessonDescription; better sqlite initialisation

* Old Lesson class is gone, replaced with LessonDescription. All code now
  refers to the latter.

* Database.{dev,test,prd} all defer to Database.init(label), which ensures
  label is one of {dev,test,prd}, ensures no other database has been loaded,
  and caches the Database object for future calls. So calling Database.dev
  followed by Database.test will generate an error.

* LessonDescription is defined in lib/school\_record/lesson\_description.rb.
  I moved it back out of DomainObjects. It is required by the Datamapper
  initialization code (i.e. just-in-time). I thought about another module
  DatabaseObjects but decided against it. LessonDescription is as core as
  Calendar or Timetable, which are both in the SchoolRecord namespace.

* Database initialisation code is fresher; ensures only one of
  {dev,test,prd} is loaded.

* Removed test database to force clean regeneration.

* All tests pass except for the Obstacle one involving period 4, which all
  this refactoring is aiming to fix.

## Introduce Lesson, where schoolday may be nil

The simple Lesson class can go in DomainObjects. I'm still not sure how it's
going to be used, especially regarding the possibly nil schoolday. The way I
see it, it's just a value object and may not get used in many places. But
even if it is just used to help create TimetabledLesson objects, that is a
job well done. Anyway, we'll see.

One place where Lesson needs to be used is Obstacle. Instead of storing an
array of schooldays and an array of classes and a single period (that
doesn't make sense), it can store:

* An array of dates (not schooldays, dates)
* An array of Lessons:
    * The schoolday in each is nil
    * The class\_label is defined
    * The period may or may not be nil

So the following obstacle yaml snippets would produce the subsequent
Obstacle object.

    - dates: ['11A Mon', '11A Thu']
      class: 7
      reason: Exams

         -->  Obstacle:
                dates == (2012-04-09 .. 2012-04-12)
                lessons == [ Lesson:nil,7,nil ]
                reason == "Exams"

    - date: 5 June
      classes: 10(1),7
      reason: Prefect induction

         -->  Obstacle:
                dates == (2012-06-05 .. 2012-06-05)
                lessons == [ Lesson:nil,10,1 ; Lesson:nil,7,nil ]
                reason == "Prefect induction"

Then when Obstacle#match? is called, it is with a Lesson object that has all
three fields filled, and we use them to determine whether the date, class
and period match the obstacle.

> Note: if an obstacle doesn't have the period specified, it's because that
> class only has one lesson that day, so if the class matches, then _of
> course_ the obstacle affects that lesson.

    def match?(lesson)
      sr_int "Obstacle#match? -- lesson argument incomplete" unless
        lesson.fully_specified?
      match = lesson.schoolday.date.in? @dates and
                lesson.class_label.in? @class_labels
      if match and @period.nil?
        true
      elsif match and @period == lesson.period
        true
      else
        false
      end
    end

The other thing that has to be done is parse the period information on the
way in -- that is, the "11(4)", for example.  (Done.)

While I'm at it, I'd like to allow a nice easy way to specify a range of
dates: `- dates: 11A Mon --> 11A Thu`. (Done.)

Now I'm implementing #match?  Wow, I can't believe the code I wrote for it
just above. It uses @class\_labels and @periods, but I don't have those
anymore. The point of introducing Lesson was to get rid of those things!

I've done a decent implementation, but the tests are failing. It turns out
the strings are not being parsed correctly on the way in. That's where I
pick it up tomorrow.

(20 Feb 2012)

After some fiddling around, it's pretty sweet to see this:

    +----- Report ---------------------------------------------------------------+
    |                                                                            |
    |  Obstacle.from_yaml                                                 -      |
    |    Creates an array of Obstacles                                    PASS   |
    |    First one: 5 Jun                                                 PASS   |
    |    Second one: 12B-Wed                                              PASS   |
    |    Third one: 9A Mon --> 9A Thu                                     PASS   |
    |    Fourth one: Thu 14B 10(0) -- note specific period                PASS   |
    |    Fifth one: 1A Fri (Sem 2)                                        PASS   |
    |    Sixth one: 9A-Mon: 12, 11(4)  -- complex class parsing           PASS   |
    |                                                                            |
    +----------------------------------------------------------------------------+

It feels like time for a commit. I've introduced Lesson and used it in
Obstacle. There are other places to use it, sure, but this is a good
milestone.  Commit message:

     Introduced lightweight Lesson class; completed Obstacle

     * Lesson is a value object, essentially for passing parameters
       (schoolday, class_label, period).
     * Obstacle now uses Lesson objects and is implemented and tested
       properly, paving the way to...
     * TimetabledLesson (implemented but not used or tested) is a slightly
       mode robust class which encapsulates a lesson that is timetabled,
       but knows about any obstacles. (It's not a smart object; it needs
       to be told of the obstacles.) This paves the way for...
     * Database#timetabled_lessons, coming soon.

There are two things I could work on now.

* Use Lesson in more places.
* Implement Database#timetabled\_lessons.

I think I'll do them in that order.

## Use Lesson whereever possible, and make all code period-aware

Here is the output of `tree lib` with comments on actual or potential
`Lesson` usage.

    +--lib
       +--school_record/
          +--app.rb                        N/A
          +--calendar.rb                   N/A, but could use DateString
          +--command.rb                    slight potential [1]
          +--database.rb                   surprisingly little [2]
          +--date_string.rb                N/A
          +--domain_objects.rb             N/A
          +--err.rb                        N/A
          +--lesson_description.rb         N/A; very straightforward class
          +--obstacle.rb                   already using it
          +--report/
          +--report.rb                     N/A
          +--timetable.rb                  clearly should use it [3]
          +--timetabled_lesson.rb          probably not [4]
          +--util.rb                       N/A
          +--version.rb                    N/A
       +--school_record.rb                 N/A

**[1]** The EnterLesson command calls `@db.store_lesson(date_string,
class_label, description)`. That method is not properly implemented yet.
Lesson could possibly be used here, but it feels like forcing it. In this
case, EnterLesson would be responsible for calling @db.schoolday, which may
not be a bad thing: it could catch an exception and inform the user
properly.

**[2]** The only place I can see in Database that could use Lesson is
`store_lesson`, but that will be reimplemented from scratch soon and will be
using TimetabledLesson, not Lesson. Speaking of which, however, of course
`Database#timetabled_lesson` will be using Lesson. Another aside here: there
is some serious cruft to be removed from Database.

**[3]** Timetable currently has classes(), which returns an array of class
labels and periods. This is what Lessons what designed for! Probably should
use Lessons as internal representation. We'll see.

**[4]** TimetabledLesson could _have-a_ Lesson, clearly: it possesses
exactly the same properties, with the addition only of an obstacle. I won't
do this just for the sake of it though. Better would be inheritance, and
there is probably something to that, but I won't do that for the sake of it
either. TimetabledLesson is a simple enough class that there is no need to
be clever about it.

So after all that, I have:

* Timetable must be changed to use Lesson right now!
* Database will use it in `timetabled_lesson` and probably nowhere else.
* EnterLesson deserves consideration.
* Some cruft to be removed from Database and Timetable.
* Calendar should make use of DateString.

I'm surprised there is not more code that needs to be made period-aware. I
guess that just comes from focusing on one part of the system for so long.

...

I've changed Timetable::Day to use Lessons for internal representation. (A
Day is just an array of Lessons.) The API of Timetable is not totally
settled. class\_labels\_only() is really just for testing at this stage.
There's probably a better way, even if it's a method designed entirely for
testing, like

    Eq timetable.lessons_export_string(sd), "7(1), 12(3), 12(4), 10(6)"

Hmmm... good idea, actually!  Done.

Anyway, the API will develop as I implement Database#timetabled\_lesson.

OK, timetable tests pass now, and look much better too.

Committed.

Just a thought, while I'm here: the 'schoolday' property in Lesson appears
to be getting zero use so far. Perhaps I can remove it after
timetabled\_lessons is implemented.
