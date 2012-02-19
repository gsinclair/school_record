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

