# Implementing the 'note' command

I'm choosing the "note" command because it has only a small amount of
infrastructure requirements.  I need a Note class (domain object), a Database
class (backing store), and a simple ClassList implementation, perhaps a stub for
now.  (Notes are stored against a certain student in a certain class, so there
has to be some tie-in.)

## Iteration 1

My thoughts on the SR::Database class are as follows.

* It needs to store Notes and Lessons. Object-wise, it makes sense to have the
  following:

    Database
      @notes = {
        '7' =>  [Note, Note, ...],
        '10' => [Note, Note, ...],
        ...
      }
      @lessons = {
        '2012-02-01' => [Lesson, Lesson, ...],
        '2012-02-02' => [Lesson, Lesson, ...],
        ...
      }

* The backing store can be really simple to start with. I think a single YAML
  file for all notes and a single YAML file for all lessons. (Lessons are not
  being implemented today.)
    * In future, I envisage a flat text file for all notes, one file per
      year-group. Reason: can edit the text file directly if needed. And for
      lessons, it will probably be one yaml file per school day, grouped into
      directories (one per school week).

* At the moment, all notes (and soon, lessons) will be stored in memory and
  persisted to disk. Later, they (especially lessons) will be loaded on demand.

* It's really important that all access to the notes and lessons through the
  Database class be based on clean API methods so that the underlying
  implementation can change. (Should go without saying.)

As for the Note class, where should it be kept?  SR::Note is the obvious choice,
but I don't like it. I want to keep all "domain objects" together.  Perhaps
SR::DomainObject::Note, shortened via an alias to SR::DO::Note.  I'll go with
that for now and change it later if I think of something better.

A Note object contains a student's name, their class, and a string (the note).
It seems pretty obvious that the student's name and class should be combined
into a Student value object, generated by ClassList.  So...

    Student
      @first = 'Helen'
      @last  = 'Jones'
      @class_label = '9'

    Note
      @date = '2012-02-24'
      @student = <'Helen', 'Jones', '9'>
      @text = "Good work on assignment"

    Database
      save_note(note)

OK, so I've implemented the stuff above.  My Database class has nested classes
Database::Dirs (to distinguish between test and production database directories)
and Database::Files (to manage access to the notes and lessons files). Here is
the Database class itself in full.

    class Database
      def Database.test
        @testdb ||= Database.new( Dirs.test_database_directory )
      end
      def initialize(directory)
        @notes = Hash.new { |hash, key| hash[key] = Array.new }
        @files = Files.new(directory)
      end
      def save_note(note)
        @notes[note.class_label] << note
        @files.notes_file.open('w') do |out|
          out.puts YAML.dump(@notes)
        end
      end
      def load_notes
        @notes = YAML.load(@files.notes_file.read)
      end
      def contents_of_notes_file    # for casual testing
        @files.notes_file.read
      end
    end  # class Database

Now to work on the App side of things, in SR::Command::NoteCmd. It currently
reads:

    class SR::Command::NoteCmd
      def run(args)
        puts "Command: note"
        puts "Arguments: #{args.inspect}"
      end
    end

If it's given the arguemnts `['9', 'Helen', 'Good work on assignment'] then the
code needs to:

* Turn `['9', 'Helen']` into a Student object
    * This requires the ClassList class, which I don't currently have.
* Create a Note object (easy).
* Call `Database#save\_note()` (already written).
    * But I don't currently have a database object.

That last point, not having a database object to work with, is important.  I
suppose the database is a property of the App class, which can decide whether it
needs to be instantiated or not.  (E.g. you don't need a database just to print
a help message.)  The App can then pass it to each of the Command::* classes.
But here we have some commonality among these command classes, which means they
should be subclasses of the generic Command class.

    class Command
      def initialize(db)
        @db = db
      end
      def run(args)
        sr_int "Can't run generic Command object"
      end
    end

I made all the command classes inherit Command, and changed the code in App#run:

    database = Database.test
    class_for_command(command).new(database).run(args)

At this point, running `run note 9 Helen "Good work"` does exactly what it did
before, so I haven't broken anything.


## Iteration 2

Now that the basics are set up, I can attack the actual Note#run implementation.

Excerpting the relevant text from above, if it's given the arguemnts
`['9', 'Helen', 'Good work on assignment'] then the code needs to:

* Turn `['9', 'Helen']` into a Student object
    * This requires the ClassList class, which I don't currently have.
* Create a Note object (easy).
* Call `Database#save\_note()` (already written).
    * Now I _do_ have a database object.

Like this:

    cls, name, text = args.shift(3)
    student = ClassList.resolve(cls, name)
    note = Note.new(Date.today, student, text)
    @db.save_note(note)

Or with error handling and informative output included:

    def run(args)
      cls, name, text = required_arguments(args, 3)
      student = ClassList.resolve!(cls, name)
      puts "Saving note for student: #{student}"
      note = Note.new(Date.today, student, text)
      @db.save_note(note)
      puts "Contents of notes file:"
      puts @db.contents_of_notes_file.indent(4)
    end
    def usage_text
      msg = %{
        - The 'note' command takes three arguments:
        -   * class label
        -   * fragment of student's name
        -   * text for the note (in quotes, so it's one argument)
        - Example:
        -   sr note 9 JCon "Late assignment submission"
      }.margin
    end

All I need now is `ClassList.resolve!(cls, name)` and I'm done. Well, sort of. I
could implement it like that but I don't like it. I want to call `resolve!` on
an _object_, not on a _class_. And thinking about it, it should go through the
database: the classlist file is stored along with the other data. It's more
"configuration" than "data", so I guess I could have a Config class, but I'll
stick with Database for now and reconsider it later.

To handle the loading and stuff, I think I need a plural class as well:
ClassLists.

Nup, stuff it. I'm going to keep it simple for now. It's all handled through
Database. Database can handle a hash of classes (keyed by class label)

    class SchoolClass
      def initialize(label, full_name, student_names)
        @label, @full_name, @student_names = label, full_name, student_names
      end
      attr_reader :label, :full_name
      def resolve(name_fragment)
        # ... return Student object if we can match the fragment ...
      end
    end

    Database
      @classes = { '7' => SchoolClass, '8' => SchoolClass, ... }
      load_class_lists
      valid_class_label?(label)
      resolve_student(cls, name_fragment)
      resolve_student!(cls, name_fragment)

    class Name    # Used for student names
      @first
      @last
      name

So now it's not (1), it's (2).

    (1) student = ClassList.resolve!(cls, name)
    (2) student = @db.resolve_student!(cls, name_fragment)

I feel better about that.

OK, I've implemented SR::DO::Name (and changed Student to use it) and
SR::DO::SchoolClass, including #resolve and #resolve! Now for the Database
part. Then I need to write some unit tests to check that #resolve works as
intended.

I've implemented the following in Database:

    def initialize(directory)
      @files = Files.new(directory)
      @classes = load_class_lists                    # new line
        # { '7' -> (SchoolClass), '10' -> (SchoolClass), ... }
      @notes = YAML.load(@files.notes_file.read)
    end

    def load_class_lists
      data = YAML.load(@files.class_lists_file.read)
      puts "Printing class list data and exiting"
      pp data
      exit
    end
    def valid_class_label?(label)
      @classes.key? label
    end
    def resolve_student(class_label, name_fragment)
      @classes[class_label].resolve(name_fragment)
    end
    def resolve_student!(class_label, name_fragment)
      @classes[class_label].resolve!(name_fragment)
    end

I've hand-crafted the file test/db/class-lists.yaml following the format I laid
out in doc/brainstorm.md, with the exception that the names are sensible LAST,
FIRST, and the addition of departures and arrivals:

    Year11:
      label: '11'
      full_label: '11MTA'
      full_name: '11 Advanced Mathematics A'
      students:
       - Abi-Hanna, Stephanie
       - Blake, Jessica
       - Burke, Anna
       - Courtney, Clare
       - Earls, Frances
       - ...
       - Pithers, Eliza
       - Santoso, Cathleen
       - Smythe, Isabella
      departures:
       - "Moody, Georgia: 27 AUG"
       - "Courtney, Clare: 4 SEP"
       - "Lawrence, Brittany: 19 MAY"
      arrivals:
       - "Earls, Frances: 15 JUN"

The departures and arrivals bit won't be implemented straight away, but that
seems like a good way to record them. I'm undecided whether a name should still
be in the list after they leave the class. (Probably not.)  Taking account of
departures and arrivals will make the SchoolClass class more complex, but that's
not a problem for now.

Anyway, I just want to get the program to load this data, print it out, and
exit.  ...And, it did!  The only bugs I had were lack of requires.  The data
looks great, now I can turn it into SchoolClass objects.

Done:

    def load_class_lists
      data = YAML.load(@files.class_lists_file.read)
        # See file class-lists.yaml for the format of the data.
      result = {}
      data.each do |key, hash|
        label, full_label, full_name, students =
          hash.values_at('label', 'full_label', 'full_name', 'students')
        students = students.map { |str|
          last, first = str.split(', ')
          SR::DO::Name.new(first.strip, last.strip)
        }
        result[label] = SR::DO::SchoolClass.new(label, full_label, full_name, students)
      end
      result
    end

I also had to tighten up the loading of the notes file. Since it didn't exist,
and then when it existed it didn't have any data in it, the @notes variable
didn't have a hash in it. I handled that case and raised an internal error in
the event that the file was corrupted.

And now it works!

    $ run note 9 MAch "Equipment"
    school-record version 0.0.1.pre
    Saving note for student: Mikaela Achie (9)
    Contents of notes file:
        ---
        '9':
        - !ruby/object:SchoolRecord::DomainObjects::Note
          date: 2012-01-28
          student: !ruby/object:SchoolRecord::DomainObjects::Student
            name: !ruby/object:SchoolRecord::DomainObjects::Name
              first: Mikaela
              last: Achie
            class_label: '9'
          text: Equipment

After getting it to run and mucking around a bit, I added Database.dev, located
in etc/dev-db, and which contains a symlink to the test/db/class-list.yaml file.
Now I can muck around in development, making use of the class list, but without
writing anything to the test database.

# Iteration 3: unit testing

I've implemented the files test/{class\_list,database}.rb with pretty thorough
testing of these things.  Here's the current report.


     +----- Report ---------------------------------------------------------------+
     |                                                                            |
     |  Database                                                           -      |
     |    Can be loaded (test database)                                    PASS   |
     |    When it's loaded                                                 -      |
     |      It can resolve student names                                   PASS   |
     |      It can resolve! student names                                  PASS   |
     |      It can access the saved notes ('notes' method)                 PASS   |
     |                                                                            |
     |  SchoolClass                                                        -      |
     |    resolve                                                          -      |
     |      Returns objects of type Student with correct class label       PASS   |
     |      Can find three people called Emma                              PASS   |
     |      Can find one person named Sarah                                PASS   |
     |      Can resolve NC, NCh, NChe, NChen, NiC, NicC, NiCh, NiChe and   PASS   |
     |      Can resolve MAch and MDe                                       PASS   |
     |      Finds the two matches for AKirk and AK                         PASS   |
     |      Can resolve surname fragment 'Jia'                             PASS   |
     |      Finds nobody named Foobar or FooBar                            PASS   |
     |      Raises SRError when given invalid fragments                    PASS   |
     |    #resolve!                                                        -      |
     |      Returns a Student, not an array                                PASS   |
     |      Raises SRError when no match is found                          PASS   |
     |                                                                            |
     +----------------------------------------------------------------------------+

    ================================================================================
     PASS     #pass: 15    #fail: 0     #error: 0     assertions: 64    time: 0.005
    ================================================================================

Pretty happy with that!  Time for a commit.

Possible next steps:
 * report on notes
 * better backend representation of notes (the current YAML is ugly)
 * add lesson record
 * timetable and term dates (calendar)
