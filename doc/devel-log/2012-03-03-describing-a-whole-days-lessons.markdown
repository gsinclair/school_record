# Describing a whole day's lessons

**(3 MAR 2012)**

Now that I can put one lesson at a time into the database via the command line,
it's time to look at getting a whole day's worth of lessons in via a text
editor. This would be the 'edit' command. Here is the relevant excerpt from the
brainstorm.

    sr edit
      # Opens an editor in which I can record several classes for today. The
      # program knows what classes I have today and begins with a skeleton like
      # "Day: 2012 Sem2 10B Fri\n\n7: \n\n11: \n\n10: \n", allowing me to fill in
      # the details. Some lessons may already be described. Their data would be
      # shown for context, but commented. When I save the file, new data is
      # committed; comments are ignored. (Try to get the cursor in a useful
      # starting place. Try to detect quit without saving in order to abort.
      # Don't overwrite data without warning; give information and context. Print
      # really simple and concise report after saving the data so the new data can
      # be seen in context.)

    sr edit yesterday     (or sr edit 1)
    sr edit 2
    sr edit 3
    sr edit Mon
    sr edit Mon,Tue
    sr edit 9A-Fri
      # As above, but enter data for, respectively: yesterday, two days ago, three
      # days ago, the most recent Monday, the most recent Monday AND Tuesday, and
      # Friday of Week 9A.

    sr prompt
      # Tell me which lessons are not recorded.

    sr edit prompt
      # Open an editor containing the skeleton for missing lessons, allowing me
      # to enter them.
      # 'missing' seems like a good alternative to or alias for 'prompt'.

To implement this, I need:

* Command::EditLessons, obviously.
  * Forks and opens vim with a pre-loaded temp file.
  * Parses the edited file and puts stuff in database.
* A class that creates the temp file and parses the resulting text.
* A method (in Database?) for storing lesson descriptions.
  * I have TimetabledLesson#store\_description, but that refuses to overwrite an
    existing description, whereas when _editing_ descriptions it is OK to change
    them.

Thoughts on the file that the text editor loads:

* It should make heavy use of comments and directives. Comments for informing
  the user what data is there already, and directives for specifying the date,
  class, period, etc. Make it easy to parse.
* Obstacles must be reported (as a comment).
* It must be able to handle several days' worth of data, so dates must clearly
  be specified.

Here is how the file could look when loaded up.

    # Edit: Sem1 Tue 3A, Sem1 Wed 3A

    ~ Sem1 Tue 3A ========================================================

    ~ 10(2) Tue
    # ...

    # ~ 12(3) Tue
    # Simpson's rule worksheet (concluded), followed by practice questions.
    # ex:(3.2)

    # 11(4) Exams

    ~ 7(5) Tue
    # ...

    ~ Sem1 Wed 3A ========================================================

    # ~ 11(1) Wed
    # start:(AM2) Introduction to linear equations and graphs. ex:(7.1)

    ~ 12(2) Wed
    # ...

    ~ 7(4) Wed
    # ...

    # ~ 10(5) Wed
    # Equations with fractions. ex:(3.4)

    # vim: ft=school_record

Notes:

* Directives are lines beginning with ~; comments begin with #.
* The "Edit" line at the top is just a comment to say what days are being
  edited.
* A 'day' directive has lots of = after it to provide a visual cue.
* A 'lesson' directive has the day after it as a redundancy so the user can
  double-check they are entering information for the right day. It is probably
  ignored during parsing.
* Lessons that already have descriptions have the directive and the contents
  shown as comments. If the user wants to edit the description, they need to
  uncomment the paragraph. Of course, if they leave it alone it is nothing but a
  comment and will be ignored.
* Lessons with obstacles are simply shown as a comment with the lesson and the
  reason.
* The string "# ..." is an invitation to replace that comment with a
  description. I may remove that and have nothing but a blank line instead.
* There is vim filetype information down the bottom because I'd like to create a
  syntax highlighting file.

Parsing this file wouldn't be difficult. It would end up creating an array of
hashes/objects like this:

      schoolday: ...
      descriptions:
        { Lesson => "...", Lesson => "...", ... }

Once that is done, I suppose the approach would be to get the TimetabledLesson
objects for the particular schoolday, match them with the Lesson objects in the
hash, and call store\_description (with a flag indicating that overwriting is
allowed).

The command could prompt the user for confirmation that a description is to be
overwritten. The user could respond y/n/a (yes/no/all), the 'all' giving
approval for all such edits.

One comment on the parsing of the descriptions themselves: newlines should not
be preserved, except when a new paragraph is formed (two or more consecutive
newlines). The description is essentially a list of words separated by a single
space, with occasional (and not often used, I expect) paragraph breaks. When
descriptions are reported, their contents will be reflowed as necessary.

So, code outline:

    Command::EditDescriptions
     * Has to determine from the command-line arguments what dates are to be
       edited.
       * '4' means four days ago.
       * '2-4' means two to four days ago.
       * 'Tue', '3A Mon', 'yesterday' etc are obvious and can already be handled
         by Database#schoolday.
       * 'Mon-Wed' is less obvious and means Monday to Wednesday.
       * 'missing' means all missing lessons, and will not be implemented at the
         moment.
       * Note that the code to handle "four school days ago" doesn't yet exist.
     * Calls on EditFile::Creator to create the input file.
     * Forks and opens the file in vim.
     * When the editing is complete, calls on EditFile::Parser to generate the
       array of hashes/objects.
     * Calls on Database#store_lesson_descriptions to put those descriptions in
       the database.
     * Finally, it should present some sort of report to the user, like the full
       contents of the days involved.

    EditFile::Creator.new(db).generate(schooldays)
     * Calls `db.timetabled_lessons` for each of the schooldays so that lessons
       and obstacles are known.
     * Generates the string content of the file.
     * Does this class save the file? Or just pass back the string?
       * Probably just pass back the string.

    EditFile::Parser.new(data).parse
     * Essentially a state machine, looking for directives to change its state
       and generate the structure needed.

    Database#store_lesson_descriptions(array)
     * The argument is an array of hashes or objects containing keys/methods
       'schoolday' and 'descriptions', which is a hash indexed by Lesson
       objects.
     * It retrives the TimetabledLesson objects for the given schoolday and
       matches them up against the given data, to make sure there's nothing
       extra provided.
     * Assuming all is in order, it calls TimetabledLesson#store_description and
       specifies that overwriting is OK. I don't know how that enables
       communication with the user, because this code is not in EditDescriptions.
     * Because of the complexity of the matching process, I can see this
       functionality being performed by a dedicated class.

**(4 MAR 2012)**

These things can be done one at a time. I will tackle the edit file creator and
parser first (and test them as I go) before doing the others.

## Iteration 1: EditFile::Creator

Implemented and tested.

    D "EditFile::Creator" do
      D.< {
        @db = SR::Database.test
        insert_test_data_efc
      }
      D "#create" do
        sd1 = @db.schoolday("5 June 2012")
        sd2 = @db.schoolday("6 June 2012")
        str = SR::EditFile::Creator.new(@db).create([sd1, sd2])
        Eq str.strip, expected_output.strip
      end
    end

