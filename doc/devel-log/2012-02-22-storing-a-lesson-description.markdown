# Storing a lesson description

While still working on the tests of TimetabledLesson, I want to have a stab at
writing Database#store\_lesson.

    def store_lesson(date_str, lesson, desc)
      sd = schoolday(date_str)
      sd_str = sd.full_sem_date
      tls = timetabled_lessons(sd, lesson.class_label)
      if (pd = lesson.period)
        tls = tls.select { |tl| tl.period == pd }
      end
      lds = LessonDescription.all_by_day_and_class(sd_str, lesson.class_label)
      # ...
    end

It would be convenient at the moment for TimetabledLesson to be able to manage
its own description:

    def store_lesson(date_str, lesson, desc)
      sd = schoolday(date_str)
      sd_str = sd.full_sem_date
      cl, pd = lesson.class_label, lesson.period
      tls = timetabled_lessons(sd, cl)
      if (pd = lesson.period)
        tls = tls.select { |tl| tl.period == pd }
      end
      # We now have a list of timetabled lessons in which a description could be
      # put. We haven't considered obstacles yet, nor whether the lesson
      # already has a description.
      tls = tls.select { |tl| ! tl.obstacle? }
      tls = tls.select { |tl| tl.descripion.nil? }
      tl = tls.first
      # tl is the lesson that should get the description.
      if tl.nil?
        sr_warn "Cannot find a lesson in which to store the description"
      else
        tl.store_description desc
      end
    end

That requires two methods, both of which I am comfortable with.

    TimetabledLesson#description
    TimetabledLesson#store_description

The funny thing, however, is that this code does not belong in Database; it
belongs in the command (EnterLesson, though DescribeLesson would be better).
Reason: the complexity of the code is _finding the right lesson to describe_,
which is an application thing. Consider that information may need to be relayed
to the user at various points, and it's clear that the command should handle
this. Database may be able to provide extra support, but schoolday,
timetabled\_lessons, and the planned additions to TimetabledLesson may be all
the support it needs.

## Iteration 1: reading lesson description from database

Changed EnterLesson to DescribeLesson.

Changed App#run so that class labels are recognised as a command, like

    sr 10 yesterday "Sine rule..."

Implemented Database#schoolday!(str) -- errors if not a school day.

Implemented DescribeLesson#run. Quite long but reasonably straightforward.


    # E.g. The following two are equivalent and must be handled carefully.
    #   run("enter", ["10", "yesterday", "Sine rule..."])
    #   run("10", ["yesterday", "Sine rule..."])
    def run(command, args)
      class_label = (command == "enter" ? args.shift : command)
      err :invalid_class_label unless @db.valid_class_label?(class_label)
      args = required_arguments(args, 1..2)
      description, date_string = args.pop, args.pop

      sd = @db.schoolday!(date_str || 'today')
      emit "Retrieving lessons for #{sd.full_sem_date}"
      ttls = @db.timetabled_lessons(sd, class_label)
      
      # We now have all the timetabled lessons for this class on this day.
      # There could be obstacles, though. Report to the user if there are. Select
      # the first non-obstacled, non-described lesson for saving the description.
      if ttls.empty?
        emit "  - no lessons for #{class_label} on this date"
        exit!
      end

      lesson = ttls.find { |l| l.obstacle.nil? and l.description.nil? }
      if lesson
        lesson.store_description(description)
        emit "Stored description in period #{lesson.period}"
      else
        # Report to the user.
        pds = ttls.map { |l| l.period }.join(', ')
        emit "#{class_label} lessons for #{sd.sem_date}: #{pds}"
        ttls.each do |l|
          if l.obstacle?
            emit "- can't store in pd #{l.period}: #{l.obstacle.reason}"
          elsif l.description
            emit "- can't store in pd #{l.period}: already described"
            emit l.description.indent(8)
          end
        end
      end
    end

What is required to make this work:

* TimetabledLesson#description
    * Retrieve lesson description from database (and cache)
* TimetabledLesson#store\_description
    * Write description to database and replace cache

I wonder if I'll be able to unit test this...

**(26 FEB 2012)**

I _am_ unit testing this with the following code in test/timetabled\_lesson.rb:


    D "TimetabledLesson" do
      D.<< {
        @db = SR::Database.test
        insert_test_data
      }
    ...
    def insert_test_data
      adapter = DataMapper.repository(:default).adapter
      adapter.execute "delete from school_record_lesson_descriptions"
      data = %{
        Sem1 1A Fri|10|5|start:(Arithmetic) Overview of number systems...
        Sem1 1A Fri|7|6|start:(Whole Numbers) Introduction to high sch...
        Sem1 2B Mon|10|0|Marked arithmetic pretest. Rushed through 1.1...
      }
      stmt = "insert into school_record_lesson_descriptions " \
             "(schoolday, class_label, period, description) " \
             "values (?, ?, ?, ?)"
      data.strip.split("\n").each do |line|
        sd, cl, pd, desc = line.strip.split('|')
        adapter.execute(stmt, sd, cl, pd.to_i, desc)
      end
    end

(Some lines truncated for readability.) There are comments in the test file to
explain that _all_ we are testing here is TimetabledLesson#description (and
\#store\_description).

In the first attempt to test it, one problem has become apparent: I am using
Strings for the date of the lesson (SchoolDay#full\_sem\_date, which produces
"Sem1 1A Fri", for instance), but I got the order wrong in my test data:
"Sem1 Fri 1A", because that is how I naturally tend to write it.

Of course it's an easy problem to fix: just change the order in my test data, or
perhaps the output of SchoolDay#full\_sem\_date. But it exposes a kind of
underlying fragility in the decision to store a semester date. If I stored a
real date, like "2012-01-30", or even its corresponding Date object, this
wouldn't be a problem. But that's not such a natural fit when looking at the
data in the database.

**(27-28 FEB 2012)**

I think that if the LessonDescription object is going to work with custom
strings for school dates in the database, then it should take responsibility for
the conversion (in both directions).  I'll use a method for now, but maybe a
filter can be used.

I've got the TimetabledLesson tests passing now with the following code:


    class << LessonDescription
      def find_by_schoolday_and_lesson(schoolday, lesson)
        LessonDescription.first(
          schoolday:   sd_string(schoolday),
          class_label: lesson.class_label,
          period:      lesson.period
        )
      end

      private

      # -> "Sem1 3A Tue", for representing SchoolDay objects in the database.
      def sd_string(schoolday)
        sd = schoolday
        "Sem#{sd.semester} #{sd.weekstr} #{sd.day}"
      end
    end  # class << LessonDescription

Problem is: what about getting data _into_ the database. And the bandaid
solution above only works when the search is done using `find_by_schoolday_and_lesson`. 
The only real solution to this is to use filters, which aren't implemented
directory, or callbacks, as in (something like):

    class LessonDescription
      # properties...
      before :save do
        schoolday = LessonDescription.sd_string(schoolday)
      end

      # there's no explicitly-supported way to hook data loading...
    end

I take that back. The _best_ solution is to implement my own DataMapper type.
Here for example is a regex type (http://bit.ly/ykRhcT):

    require 'dm-core'

    module DataMapper
      class Property
        class Regexp < String
          load_as ::Regexp

          def load(value)
            ::Regexp.new(value) unless value.nil?
          end

          def dump(value)
            value.source unless value.nil?
          end

          def typecast(value)
            load(value)
          end

        end
      end
    end

And here is a CSV one:

    module DataMapper
      class Property
        class Csv < String
          load_as ::Array

          def load(value)
            case value
            when ::String then CSV.parse(value)
            when ::Array then value
            end
          end

          def dump(value)
            case value
              when ::Array
                CSV.generate { |csv| value.each { |row| csv << row } }
              when ::String then value
            end
          end

          include ::DataMapper::Property::DirtyMinder

        end # class Csv
      end # class Property
    end # module DataMapper

And here is my shiny new SchoolDay one, which works.

    module DataMapper
      class Property
        class SchoolDay < DataMapper::Property::String

          def load(value)
            # Take a string from the database and load it. We need a calendar!
            case value
            when ::String then calendar.schoolday(value)
            when ::SR::DO::SchoolDay then value
            else
              sr_int error_message(:load, value)
            end
          end

          def dump(value)
            case value
            when SR::DO::SchoolDay
              sd = value
              "Sem#{sd.semester} #{sd.weekstr} #{sd.day}"
            when ::String
              value
            else
              debug "About to raise error. value == #{value.inspect}"
              sr_int error_message(:dump, value)
            end
          end

          def typecast(value)
            debug "Called typecast: value == #{value.inspect} (#{value.class})"
            value
          end

          private

          def calendar
            @calendar ||= SR::Database.current.calendar
          end

          def error_message(method, value)
            case method
            when :load
              "Trying to load schoolday from database; " \
                "it should be a String or SchoolDay but it's a #{value.class}."
            when :dump
              "Trying to save schoolday value to database, but it's a " \
                "#{value.class} instead of a SchoolDay or String."
            end
          end

        end  # class SchoolDay
      end  # class Property
    end  # class DataMapper

There were some complications here, especially the need to access a Calendar in
order to resolve school days. Also, getting the inheritance right wasn't easy,
and the relevant DataMapper docs seem to be out of date, as I can't get the
method `load_as` to work. (But I'm sure it's in current dm-types code. Oh
well...) Finally, I'm don't really know what the `typecast` method is meant to
do or when it's called, but I _do_ know my code doesn't work without it. Unit
tests are therefore very important for this class to ensure it's working
properly. I don't want to discover data mapping problems in real use.

Upshot: LessonDescription now exposes 'schoolday' as a SchoolDay object but
transparently stores it as a String. Well done! The details of the string format
are of no concern to any other class.


     +----- Report ---------------------------------------------------------------+
     |                                                                            |
     |  TimetabledLesson                                                   -      |
     |    #description                                                     PASS   |
     |      caches                                                         PASS   |
     |    #store_description                                               -      |
     |                                                                            |
     +----------------------------------------------------------------------------+

    ================================================================================
     PASS     #pass: 2     #fail: 0     #error: 0     assertions: 6     time: 0.677
    ================================================================================

Hooray!

The #description tests populate the test database with some records:

    def insert_test_data
      adapter = DataMapper.repository(:default).adapter
      adapter.execute "delete from school_record_lesson_descriptions"
      data = %{
        Sem1 1A Fri|10|5|start:(Arithmetic) Overview of number systems. Arithmetic pretest.
        Sem1 1A Fri|7|6|start:(Whole Numbers) Introduction to high school.
        Sem1 2B Mon|10|0|Marked arithmetic pretest. Rushed through 1.1 to 1.8. Absolute values.
      }
      stmt = "insert into school_record_lesson_descriptions " \
             "(schoolday, class_label, period, description) " \
             "values (?, ?, ?, ?)"
      data.strip.split("\n").each do |line|
        sd, cl, pd, desc = line.strip.split('|')
        adapter.execute(stmt, sd, cl, pd.to_i, desc)
      end
    end

Then it tests the ability to load the description for a given TimetabledLesson
object. Note: the TimetabledLesson object doesn't _itself_ require database
access; it's only when the 'decription' method is called that a query is made.

    tl1 = SR::TimetabledLesson.new(sd1, lesson1)
    Mt tl1.description, /Overview of number systems/

Next up: TimetabledLesson#store\_description, which will _add_ a row to the
database table. (It will raise an error if such a row exists; _editing_
descriptions is not our concern at the moment.) But first, a commit.

     Lesson descriptions loaded from the database

     * TimetabledLesson#description is now implemented and (using planted
       data) tested.
     * LessonDescription.find_by_schoolday_and_lesson
     * DataMapper::Property::SchoolDay implemented to map SchoolDay objects
       to strings in the database.
     * Command::EnterLesson -> DescribeLesson (and implemented)
     * At commandline, can run "sr 10 ..." instead of "sr enter 10 ..."
     * At commandline, dates can be specified: "sr 10 yesterday ..."
     * (Note: commandline code not tested yet, even interactively.)
     * Database.current (to support LessonDescription; general use not
       encouraged).
     * Database#schoolday!(str) -- raises error if not a schoolday.

## Iteration 2: storing lesson description (creating new database row)

(Still 28 FEB 2012)

In DescribeLesson#run, there is the following code:

    lesson = ttls.find { |l| l.obstacle.nil? and l.description.nil? }
    if lesson
      lesson.store_description(description)                  # <---- NOTE
      emit "Stored description in period #{lesson.period}"
    else
      # Report to the user.
      pds = ttls.map { |l| l.period }.join(', ')
      emit "#{class_label} lessons for #{sd.sem_date}: #{pds}"
      ttls.each do |l|
        if l.obstacle?
          emit "- can't store in pd #{l.period}: #{l.obstacle.reason}"
        elsif l.description
          emit "- can't store in pd #{l.period}: already described"
          emit l.description.indent(8)
        end
      end
    end

This code hasn't been run yet, because the indicated line calls a method that
hasn't been implemented.

So what does LessonDescription#store\_description do?

* Checks to see if a description is stored there already.
    * Don't overwrite.
    - Throw exception? It's kind of unexpected behaviour, but what would
      Avdi think?
    - I think it _is_ unexpected: the user should be aware of what lessons need
      to be described before typing in.
    - So yes, throw an exception.
* If not, create a new LessonDescription object (which is implicitly saved).

Pretty simple. Here's a stab at the code:

    def store_description(description)
      if (ld = find_matching_record)
        sr_err :lesson_description_exists, ld
      else
        LessonDescription.create(
          schoolday:    @schoolday,
          class_label:  @class_label,
          period:       @period,
          description:  description
        )
      end
    end

OK, I've done it (with suitable find\_matching\_record). Now just test it on the
command line?

Running `run 10 "Inequalities with x in the denominator"` multiple times, I've
fixed minor coding errors but have now encountered a big one: the "create" call
was (silently) failing to save the new object in the database. After researching
how to work out what's going on, it turns out there is a validation error:

    Schoolday must be of type String

I guess that's because of this line of code:

    class SchoolDay < DataMapper::Property::String

I wish there was proper documentation on creating your own DataMapper types. Now
I have to look at the custom types again to find what other things inherit from
and how they behave.

The Regexp one is pretty simple:

    module DataMapper
      class Property
        class Regexp < String
          load_as ::Regexp

          def load(value)
            ::Regexp.new(value) unless value.nil?
          end

          def dump(value)
            value.source unless value.nil?
          end

          def typecast(value)
            load(value)
          end

        end
      end
    end

It is clear that a string is stored in the database (just like I want) and a
different object (Regexp) is presented to the user when that string is loaded
from the database.

Problem: I can't call that line `load_as ::Regexp` (or `load_as SR::DO::SchoolDay`
as I would do). My data\_mapper gem is up to date.

I have changed the behaviour of 'typecast':

      def typecast(value)
        # I don't know what this is supposed to do -- that is, when and why it
        # is called -- but I am aping the behaviour of the Regexp custom type,
        # which, like this one, stores as a String and loads as something else.
        debug "Called typecast: value == #{value.inspect}"
        load(value)
      end

It hasn't made any difference, except that I am seeing more calls to 'load' in
the debug log.

After a lot of hacking (printf debugging, really) I've gotten nowhere, and have
asked a question on StackOverflow.

**(3 MAR 2012)**

Got an answer on StackOverflow from Adiel Mittmann.

> It seems that the current code of dm-types at github hasn't made it to any
> official release -- that's why load\_as doesn't work in your example. But try to
> add this method:
> 
>     module DataMapper
>       class Property
>         class SchoolDay < DataMapper::Property::String
> 
>           def custom?
>             true
>           end
> 
>         end
>       end
>     end
> 
> That's working here.

And it works!!!!

    run 10 Fri "..."   # saved in Friday pd 4
    run 10 Thu "..."   # saved in Thu pd 0
    run 10 Thu "..."   # saved in Thu pd 1
    run 10 Thu "..."   # refused to save: no undescribed lessons that day

And the database:

    sqlite> select * from school_record_lesson_descriptions;
    1|Sem1 5A Fri|10|4|Inequations with x in denominator
    2|Sem1 5A Thu|10|0|Quadratic inequations
    3|Sem1 5A Thu|10|1|Graphical methods

Awesome!!!

So TimetabledLesson#store\_description has now been tested on the command-line,
but not in a unit test.

In fact, I've tested all of DescribeLesson#run on the command-line:

* Lesson desriptions are stored to the database.
* If there are two periods in the day, they are described in order.
* If there are no timetabled lessons that are undescribed, the description is
  not saved and the appropriate reason is given: already described; or obstacle.

I just implemnted the store\_description test:

    D "#store_description" do
      sd = @db.schoolday "Sem1 2A Tue"
      lesson = SR::DO::Lesson.new('12', 3)
      tl = SR::TimetabledLesson.new(sd, lesson)
      # Start by asserting that it doesn't already have a description associated.
      N tl.description
      # Now store one.
      tl.store_description "Simpson's rule"
      # Check that it is stored.
      Eq tl.description, "Simpson's rule"
      # But that could be cached. Try a fresh object.
      Eq SR::TimetabledLesson.new(sd, lesson).description, "Simpson's rule"
      # Let's be really paranoid and access the database ourselves.
      ld = SR::LessonDescription.all(schoolday: sd, class_label: '12', period: 3)
      Eq ld.size, 1
      Eq ld.first.description, "Simpson's rule"
    end

And it passes. The row is added to the database.

I suppose I should check that it raises an exception if it is asked to overwrite
a description.  Done.

Time for a commit. It would be nice to unit-test DescribeLesson#run, but it's
not going to happen right now.

     Lessons can now be described on the command-line
     
     * TimetabledLesson#store_lesson implemented and tested.
       * Raises error if asked to overwrite existing description.
     * Every aspect of this command tested interactively (but not automatically)
       * Will describe first available period in the day, thus allowing for
         describing double periods with two iterations.
       * If no suitable lesson is available on the date requested, the user is
         informed: either that class has no lessons that day, or they're already
         described, or there is an obstacle.
     * Database#timetabled_lessons now takes second argument (class label) to
       filter the results.
     * SchoolDay#inspect.
     * The SchoolDay datamapper type now works both ways (it was read-only before)
       thanks to the method "def custom?() true end". Thanks to Adiel Mittmann on
       StackOverflow.
     * Some no-longer-used code and some debugging statements removed.

Soon after, a minor change and another commit.


     Error messages have better backtrace
     
     Any error initiated by sr_err will now start the backtrace where that
     call is made, rather than inside sr_err itself.

And then, unit testing of DescribeLesson.

     DescribeLesson command is unit tested
     
     * Database#clear_sqlite_database for testing purposes (will only
       clear the :test database)

Next up: describing a whole day's lessons.
