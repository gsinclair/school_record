require 'stringio'

D "Notes report" do
  D.<< { @db = SR::Database.test }
  D.<  { @out = StringIO.new }

  D "Report on a single student" do
    SR::Report::Notes.new(@db, @out).run(['12', 'IHen'])
    report = Col.uncolored(@out.string).lines.to_a
    Mt report[0], /Isabella Henderson \(12\)/
    Mt report[1], /28 Jan\s+Assignment not submitted/
    Mt report[2], / 3 Feb\s+Assignment submitted late/
  end

  D "Report on a whole class (1)" do
    SR::Report::Notes.new(@db, @out).run(['12'])
    report = Col.uncolored(@out.string).lines.to_a
    Mt report[0], /^$/
    Mt report[1], /Anna Burke \(12\)/
    Mt report[2], /28 Jan\s+Good work on board/
    Mt report[3], /^$/
    Mt report[4], /Isabella Henderson \(12\)/
    Mt report[5], /28 Jan\s+Assignment not submitted/      # Note: date order
    Mt report[6], / 3 Feb\s+Assignment submitted late/
  end

  D "Report on a whole class (2)" do
    SR::Report::Notes.new(@db, @out).run(['10'])
    report = Col.uncolored(@out.string).lines.to_a
    Mt report[0], /^$/
    Mt report[1], /Mikaela Achie \(10\)/
    Mt report[2], /28 Jan\s+Missing equipment/
    Mt report[3], /^$/
    Mt report[4], /Angela Kirkby \(10\)/      # Note: Angela before Anna.
    Mt report[5], /13 May\s+Late to class/
    Mt report[6], /^$/
    Mt report[7], /Anna Kirkby \(10\)/
    Mt report[8], /20 Apr\s+Talking too much/
  end

  D "Error when student fragment is ambiguous" do
    E(SR::SRError) { SR::Report::Notes.new(@db, @out).run(['10', 'AnKir']) }
    Mt Whitestone.exception.message, /Multiple students match/
  end

  D "Error when class label is invalid" do
    E(SR::SRError) { SR::Report::Notes.new(@db, @out).run(['x', 'JSmith']) }
    Mt Whitestone.exception.message, /Invalid class label: "x"/
  end

  D "Message when there are no notes for given student" do
    SR::Report::Notes.new(@db, @out).run(['12', 'JBla'])
    report = Col.uncolored(@out.string).lines.to_a
    Mt report[0], /No notes for Jessica Blake \(12\)/
  end
end
