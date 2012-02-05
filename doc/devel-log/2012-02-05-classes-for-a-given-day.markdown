# Classes for a given day

Having implemented Calendar#schoolday it is now possible to determine the
lessons that a particular day contains.  This is how I envisage it.

    lessons = @db.lessons('yesterday')     # -> Lessons object
    if lessons.school_day?
      puts "The lessons on this day are: #{lessons.lessons.inspect}"
    else
      puts "There are no lessons this day (#{lessons.reason})"
    end

An alternative is this:

    lessons = @db.lessons('yesterday')     # -> Array
    if lessons
      puts "The lessons on this day are: #{lessons.inspect}"
    else
      reason = @db.calendar.what_type_of_day('yesterday')
      puts "There are no lessons on this day (#{reason})"
    end

I think the first one is better.  So far, a Lessons object is just a value
object to convey information about what lessons are on for a given day.  (That
is, just an array of strings: ['7', '12', '11'].)

    class Lessons
      schoolday?
      schoolday
      lessons
      reason
      initialize(schoolday, lessons, reason)

However, this is smelling of YAGNI.  So I'll go for the simplest API at the
moment and see what I actually need when implementing the commands.  That
simplest API is

    @db.lessons('Fri 13A')    # -> ['11', '11', '10', '7']
    @db.lessons('Sat')        # -> nil

I'll need some way of recording a day's worth of lesson _notes_, but that's for
the future.  (Probably a class LessonNotes.)

Actually, I think a better name for this is 'timetable'.  Which of these sounds
better?

    (A) What is my timetable for Tuesday?
    (B) What are my lessons on Tuesday?

I think (A).  Saying "What are my lessons for Tuesday?" sounds like a deeper
question: what am I actually doing with my classes on Tuesday.  I suppose
another option is

    (C) What classes do I have on Tuesday?

So which should it be?

    @db.lessons('Tue')
    @db.timetable('Tue')
    @db.classes('Tue')

I think at the moment I'll go with "timetable".  But there's a slight problem.
We already have

    @db.timetable           # -> Timetable

I think it will be OK to make double use of this method:

    @db.timetable           # -> Timetable
    @db.timetable('Fri')    # -> ['11', '11', '10', '7']

As I went to write tests for this, I noticed in test/timetable.rb:

    Eq timetable.lessons(sd01), ['10','11','7','12']

There's that "lessons" again.  I think it would read better as

    Eq timetable.classes(sd01), ['10','11','7','12']

especially since what is being returned is an array of class labels.

* OK, that's done.

Now, while implementing Database#timetable(str), it occurred to me that a better
choice would be Database#classes(str).  That makes it consistent with the
Timetable object.

    @timetable.classes(school_day)   # -> ['10','11','7','12']
    @database.classes(date_string)   # -> ['10','11','7','12']

Done.  Here's the relevant part of the unit test.

    D "It can look up the classes for any date" do
      @db.calendar.today = Date.new(2012, 8, 23)   # Sem2 Thu 6B
      Eq @db.classes('today'),         %w[10 10 7 11]
      Eq @db.classes('yesterday'),     %w[12 11 10 7]
      Eq @db.classes('Monday'),        %w[10 7 12 11]
      Eq @db.classes('Mon'),           %w[10 7 12 11]
      Eq @db.classes('Fri'),           %w[11 11 10 7]
      Eq @db.classes('24 May'),        %w[10 10 7 12]
      Eq @db.classes('Fri 3A'),        %w[11 11 10 7]
      Eq @db.classes('Sem1 Fri 3A'),   %w[11 11 10 7]
      Eq @db.classes('Sat'),           nil
      Eq @db.classes('Sun'),           nil
      Eq @db.classes('11 Jul'),        nil
      @db.calendar.reset_today
    end

## Public holidays, staff days and obstacles

Without looking at the code, I'm not sure whether public holidays etc. are
accounted for in @db.classes. I think they probably are, but I'm not sure. It
needs to be decided and documented. Of even greater interest is _obstacles_
(e.g. exams, excursions), which I haven't implemented yet. Clearly there needs
to be a way to know what classes are actually being taught on a given day. But I
don't want an obstacle, say a rememberence assembly, to "wipe out" the class for
that day. Rather, I want the reason for the missed class _noted_.  That is, I
imagine objects something like these:

    Lesson
      schoolday: 'Sem2 Thu 13A'
      class_label: '10'
      notes: "5QQ on trig expansions, then double-angle formulas.
              hw:(7.05 not Q2)"
      #missed?  -> false

    MissedLesson
      schoolday: 'Sem2 Thu 13A'
      class_label: '7'
      reason: 'Rememberence Day assembly'
      notes: '(Rememberence Day assembly)'
      #missed?  -> true

It would appear that MissedLesson < Lesson, adding 'reason', redefinining
'notes' and overriding 'missed?'

OK, I haven't looked at the code, but I think @db.classes(date) will return nil
if there is no school that day (public holiday, etc.). In fact, I'm pretty sure,
and now had better test and document it. "No school that day" is different from
"Year 7 is on excursion that day" because "No school" affects all classes,
meaning _no_ lessons can be recorded that day, and public holidays are
unchangeable whereas excursions are not.

* Documented and tested.

That's it for this session. Time for a commit.
