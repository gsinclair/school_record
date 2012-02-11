# Entering lesson notes

It's time to think about how to implement the command

    sr 10 "Cosine rule worksheet. hw:(7-06 Q1-4 Q5esq)"

The workflow would seem to be this:

* Recognise the 'command' 10 as one of the valid class labels and defer to
  Command::EnterLesson or some such.
* Because no date is specified, we are entering it against today's lessons.
* Access today's lessons from the database (Lessons? LessonForDay? ???)
* Store the string "Cosine rule..." against class '10' in the Lessons (or
  whatever) object.
    * I could see Year 10 twice that day. Store it in the first empty slot. If I
      find I've done the wrong thing I can edit it later.
    * If there are no empty slots, I guess that raises an error. Maybe there
      could be a command-line "force" flag, but then how do you know which of
      the potentially two or more slots you are supposed to force? I think it's
      better to leave it to the editing capability rather than over-engineer
      this "quick" way of getting info into the system.
* Ask the database to save the Lessons (or whatever) object.

That's actually pretty easy. Of course, the devil is in the detail, starting
with: what do I call the class that represents a day's worth of lessons? I think
that class is important for the following reasons:

* I've already decided that there will be one file per day for lesson notes, and
  I believe that is a good decision from the point of view of loading and saving
  data.
* The lessons of a day are very much tied up in that day because there are
  obstacles (exams, excursions, ...) that take place on specific days.

There also needs to be a Lesson object that encapsulates a single lesson
(containing the schoolday, the class label, the string that records the lesson,
and the metadata that is parsed from that string, such as homework, start/end
topic, etc.)  It's pretty clear that this class _should_ be called Lesson.

An alternative to a Lessons class that aggregates a day's lessons would be to
just have a big pool of Lesson objects that can be searched using the #select
method, like:

    lessons.select { |l| l.schoolday = calendar.schoolday('Fri 14B') }
    lessons.select { |l| l.class_label == '7' and
                           l.schoolday.date.in? ('2012-04-01'..'2012-04-16') }
    lessons.select { |l| l.class_label == '11' and l.topic == 'AM2'}

> Note that Lesson#topic is something I just made up. The topic of a lesson can
> be inferred by looking back at previous lessons until you find a "start:(...)"
> somewhere. Lessons can also be marked "off-topic" by including the tag "ot"
> with a reason, like "ot:(Went through exam)". Such lessons would not be
> counted against the current topic.

These sound pretty tempting, actually. One problem is matching up with storage,
but that can be solved by changing the storage to a relational database, or a
NoSQL database, or something of my own creation. I chose the "daily YAML file"
storage approach for simplicity, editabilty, and lazy loading. And I'm not sure
how code like the above examples works with lazy loading. With the Lessons
approach (taking Lessons as the name of the class that aggregates one day), the
system is less helpful and forces me, the programmer, to know what days I want
to load. There will be times that I need to load the whole year's worth, but
most of the time only a small amount of data needs to be loaded.

But it still sounds tempting, especially because once you get into reports,
there's nothing special about a day's worth of classes. Many reports will look
at what a class has done over time, not at what took place on a given day.
Asking for the recent activity of Year 7 should not theoretically mean we need
to load data for other year groups, but if I use the daily YAML file approach,
we will have no choice but to load other data.

A relational database is sounding more and more like the ticket. _Except_: how
do I sync the relational database (an inscrutable binary file) in Dropbox? It
would not be efficient. Maybe a NoSQL approach? I don't know much about those,
but perhaps there's a sync-efficient file structure available. On the other
hand, a NoSQL probably wouldn't give me the structure I require to make the
variety of queries efficient.

Reading about DataMapper makes it even more tempting. But I think I'll go with
the YAML approach for now, and try to keep it simple. If I find I am exceeding
the bounds of simplicity, I'll reconsider going for a database.

With that in mind, I need a Lessons class to aggregate the lessons for a day.

> _Aside_: it is tempting to add knowledge of periods to the timetable. Then the
> report on (say) the last three weeks of Year 10 can state the period the
> lesson took place. It can also act as a way of distinguishing between the two
> times I see some classes on some days.

## Architecture

First the Lesson class.

    class Lesson
      schoolday      # the date of the lesson (SchoolDay)
      period         # what period it is      (Integer; not implemented)
      class_label    # what class it is       (String)
      record         # description of the lesson (String)
      #topic         # go back and determine what topic it is
                     #   (or maybe store it)
      #metadata      # access to the metadata stored in the description
                     #   (homework, start/finish topic, off-topic, etc.)
      #missed?       # false
      .load(hash)    # create a Lesson object from a hash taken from the YAML
      #dump          # returns a hash that can be saved in YAML

    class MissedLesson < Lesson
      schoolday
      period
      class_label
      record         # will be blank
      reason         # why this lesson was missed (String)
      #topic         # nil
      #metadata      # nil
      #missed?       # true

Then the aggregate.

    class Lessons
      schoolday      # the date of these lessons (SchoolDay)
      @lessons       # array of lesson objects, maybe like
                     #   [ [10, <lesson>], [7, <lesson>], [10, <lesson>] ]
                     #   to account for doubles.
      #store_lesson('10', "...")
                     # puts the text into the next available '10' lesson slot,
                     #   or raises an error if there isn't one
      .load(sd)      # manage the loading from the filesystem
      #save          # store the data to the filesystem

MissedLesson objects are created at runtime by reference to stored obstructions
(I haven't implemented this yet), rather than saved. I'd like to save them, but
when? And what if the obstruction data changes? I guess that once a schoolday is
in the past, it's too late to change an obstruction: it either happened or it
didn't. But I could have had an erroneous config file and change it after the
fact. But then I guess I could just edit the lesson (through the app or
directly) as well.

It's a slight conundrum, but I think I'll go with generating MissedLesson
objects at runtime so that there's no threat of inconsistency.

I'm not completely sure of the loading and storing mechanisms. It seems fine for
Lesson to read and write a hash, and let someone else do the filesystem work.
But should that someone be Lessons? I think it should be Database: that's what
it's for, really. The following set of methods is a brainstorm.

    class Database
      @lessons_by_day   # Hash: sd -> Lessons
      @lessons          # Array: Lesson objects (allowing more flexible search)
      lessons(sd)       # -> Lessons, which will either be reified from the
                        #    filesystem or retrieved from memory
      load_lessons(date_range)
                        # Doesn't return anything; just makes sure the lessons
                        #   for the given date range are loaded, thus allowing
                        #   flexible queries.
      load_all_lessons  # What it says.
      search_lessons(date_range, &block)
                        # This might make load_lessons redundant (or at least
                        #   private).
      save_lessons(sd, lessons)
                        # This could be the way that a day's worth of lessons
                        #   is saved to disk.
      save_lesson(sd, lesson)
                        # It may be worth supporting the saving of one lesson,
                        #   but probably not. (It has to go through save_lessons
                        #   anyway.)

Looks like I will need a DateRange class. And I certainly need methods that give
me "three schooldays before today", and "all the schooldays between A and B".

    class Calendar
      date_range(start, finish)  # All schooldays between start and finish,
                                 #  which are strings that can resolve to
                                 #  SchoolDay objects. (Think about that; we
                                 #  don't want to get nil back.) They can
                                 #  also be Dates or SchoolDays.
      schoolday_offset(start, offset)
                                 # e.g. schoolday_offset(Date.today, -3) gives
                                 #   you three schooldays before today, even if
                                 #   it is last term.

    class DateRange
      start, finish              # Date objects
      #include?(date or sd)
      #dates                     # [Date]
      #schooldays                # [SchoolDay]

In terms of file storage, it's already well established that a day's worth of
lessons will be stored in a single YAML file.

    2012/Sem1/03A/2012-02-13-Mon.yaml

Of course, I _could_ store lessons individually, like

    2012/Sem1/03A/Thu/10_alpha.yaml
    2012/Sem1/03A/Thu/10_1.yaml
    2012/Sem1/03A/Thu/7_2.yaml
    2012/Sem1/03A/Thu/12_5.yaml

I wonder what the performance would be like.  Obviously it would be good for
memory because it only loads what lessons it needs.  On the other hand, four
filesystem reads instead of one for a day's lessons?

Anyway, I need to do some other work now, so I'll let this stew in my brain for
a while.

## 10 Feb 2012

It's been a few days.  I intend to go with the daily YAML file because it's one
less dependency (particularly apposite since I'll be running this cross-
platform) and the least likely approach to have trouble with Dropbox.

So, to recap, this is the set of stuff I'm focusing on implementing:

* Recognise the 'command' 10 as one of the valid class labels and defer to
  Command::EnterLesson or some such.
* Because no date is specified, we are entering it against today's lessons.
* Access today's lessons from the database (Database#lessons(day) -> Lessons)
* Store the string "Cosine rule..." against class '10' in the Lessons (or
  whatever) object.
    * I could see Year 10 twice that day. Store it in the first empty slot. If I
      find I've done the wrong thing I can edit it later.
    * If there are no empty slots, I guess that raises an error. Maybe there
      could be a command-line "force" flag, but then how do you know which of
      the potentially two or more slots you are supposed to force? I think it's
      better to leave it to the editing capability rather than over-engineer
      this "quick" way of getting info into the system.
* Ask the database to save the Lessons (or whatever) object.

First up: the command. To start with (and maybe this will stick), I am requiring
the user to type "sr enter 10" instead of just "sr 10". That makes it easier to
defer to the EnterLesson class.

About the "because no date is specified", I haven't thought of a way to spec the
date on the command-line, so I'm ignoring that feature for now. Today's date is
assumed.

Here is the complete untested code for the command.

    class SR::Command::EnterLesson < SR::Command
      def run(args)
        class_label, description = required_arguments(args, 2)
        date_string = 'today'           # Maybe have a way to specify this.
        emit "Saving lesson record for class #{class_label}"
        lessons = @db.lessons(date_string)
        lessons.store(class_label, description)
        @db.save_lessons(lessons)
      end
      def usage_text
        msg = %{
          - The 'enter' command takes two arguments:
          -   * class label
          -   * string describing the lesson (use quotes)
          - Example:
          -   sr enter 10 "Cosine rule. hw:(7-06 Q1-4)"
        }.margin
      end
    end

The things that are not implemented in here are:

* Database#lessons(date\_string)
* Lessons class, with method #store
* Database#save\_lessons(lessons)

The Lesson class is also not implemented, but it's not referenced directly in
the code above.

To load a lessons file like `Sem1/02/2012-02-10-Fri.yaml` I need to define the
structure of it. I want it as simple as possible so that it can be read and
edited directly if needed.

    date: 2012-02-10
    lessons:
      - class: 10
        desc: "st:(Circle Geometry) Introduced concepts with students
               using Geogebra"
      - class: 10
        desc: "hw:(7.2 7.3)"
      - class: 7
        desc: "Dividing by two-digit number (1.10). hw:(1.10 Q1-2esq)"
        notes: "Half the class knew how to do it but still needed the practice"
      - class: 11
        desc: "Multiplying and dividing algebraic expressions; quiz on
               work so far"

Notes on the above examples:

* The structure of "class" and "desc" seems sound. It can't be a hash keyed on
  class label because there can be repeated class labels.
* I invented the "notes" part just then. Could be good; could be unnecessary.
  Not sure how it would be entered. Maybe `note:(Half the class...)`
* I formatted the multi-line strings for simplicity. Obviously YAML has its own
  way of doing that.

I'm going to ignore the "notes" idea at the moment and get the rest working.

I've created the file lesson.rb with the following contents:

    class SR::Lesson
      attr_reader :schoolday, :class_label, :text
      def initialize(schoolday, class_label, text)
        @schoolday, @class_label, @text = schoolday, class_label, text
      end
    end

    # ------------------------------------------------------------------- #

    class SR::Lessons
      attr_reader :schoolday
      # lessons_array:
      def initialize(schoolday, lessons_array)
        @schoolday, @lessons = schoolday, lessons
      end

      # Saves this day's lessons to the given output file (Pathname).
      def save(output_file)
        hash = {}
        hash["date"] = @schoolday.date
        hash["lessons"] = @lessons.map { |lesson|
          { "class" => lesson.class_label,
            "desc"  => lesson.text }
        }
        output_file.open('w') do |out|
          out.puts YAML.dump(hash)
        end
      end

      # Generates a Lessons object from a YAML file (Pathname).
      def Lessons.load(input_path, schoolday)
        hash = YAML.load(input_path.read)
        date = hash["date"]
        lessons = hash["lessons"].map { |x|
          class_label = x["class"]
          text = x["desc"]
          Lesson.new(schoolday, class_label, text)
        }
        if schoolday.date != date
          STDERR.puts "Warning: date mismatch in file for schoolday #{schoolday}"
          STDERR.puts "         The date inside the file is #{date}"
        end
        Lessons.new(schoolday, lessons)
      end
    end

That's wrong, though, because the variable @lessons in Lessons shouldn't store
an array of Lesson objects, but should store, for instance:

    [ [10, Lesson], [7, Lesson], [11, nil], [12, Lesson] ]

That is, it needs to know the scheduled lessons for the day (get it from
Database, or have it passed in? -- probably pass in a Database reference). The
above array shows that no lesson has been recorded for Year 11 yet.  The method 
call `store_lesson('11', 'Algebra blah blah')` would turn that array into

    [ [10, Lesson], [7, Lesson], [11, Lesson], [12, Lesson] ]

What about obstructions?  It would kind of make sense to have the following
array in the case of an obstruction:

    [ [10, ObstructedLesson], [7, Lesson], [11, Lesson], [12, Lesson] ]

That would probably make it easier when creating reports.  But should the
(occasional) needs of a report generator impact the (frequent) creation of a
Lessons object?  Probably not.  Reports should look after obstructed lessons
themselves.

But... it's not just reports. Editing a day's lessons should show the
obstruction, and that kind of makes it the business of the Lessons class, since
it's the very fact of editing a day's lessons that caused this class to exist.
(Otherwise, we'd just use an array of Lesson objects and leave it at that.)

But what about storage? Should an obstructed lesson be represented in the YAML
file? I don't want that. The obstruction is (or will be) recorded in the
Calendar file, from memory, and it should only be recorded once, so as to avoid
inconsistent data.

(I should just mention at this point that I'm seriously reconsidering the
relational database approach...)

OK, time to rest for the night. Committing progress.

