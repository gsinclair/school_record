def n(str)
  last, first = str.split(',')
  SR::DO::Name.new(first.strip, last.strip)
end

D "SchoolClass" do
  D.<< {
    @schoolclass = SR::DO::SchoolClass.new('9', '9MT1', '9 Math 1',
      [ n('Achie, Mikaela'), n('Bayfield, Anna-Louise'), n('Chan, Vanessa'),
        n('Chen, Karen'), n('Chen, Nicole'), n('Cooper, Ally'), n('Crimmins, Elise'),
        n('De Silva, Milena'), n('Duncan, Emma'), n('Fei, Betty'), n('Gilfedder, Lucy'),
        n('Gleeson, Emma'), n('Haldane, Kate'), n('Jiang, Linda'), n('Kench, Charlotte'),
        n('Kerr, Ella'), n('Kirkby, Anna'), n('Kostic, Rachel'), n('Kirkby, Angela'),
        n('Lowe, Sarah'), n('Marandos, Zoe'), n('McKenzie, Isobel'),
        n('Rozvany, Annaliese'), n('Wong, Kareena'), n('Xu, Danni'), n('Yates, Emma')])
  }
  D "resolve" do
    D "Returns objects of type Student with correct class label" do
      students = @schoolclass.resolve('Emma')
      F students.empty?
      Ko students.first, SR::DO::Student
      Eq students.first.class_label, '9'
    end
    D "Can find three people called Emma" do
      students = @schoolclass.resolve('Emma')
      Eq students.size, 3
      Eq students[0].fullname, "Emma Duncan"
      Eq students[1].fullname, "Emma Gleeson"
      Eq students[2].fullname, "Emma Yates"
    end
    D "Can find one person named Sarah" do
      students = @schoolclass.resolve('Sarah')
      Eq students.size, 1
      Eq students[0].fullname, "Sarah Lowe"
    end
    D "Can resolve NC, NCh, NChe, NChen, NiC, NicC, NiCh, NiChe and NicoleChen" do
      %w(NC NCh NChe NChen NiC NicC NiCh NiChe NicoleChen).each do |fragment|
        students = @schoolclass.resolve(fragment)
        Eq students.size, 1
        Eq students.first.fullname, "Nicole Chen"
      end
    end
    D "Can resolve MAch and MDe" do
      students = @schoolclass.resolve('MAch')
      Eq students.size, 1
      Eq students[0].fullname, "Mikaela Achie"
      students = @schoolclass.resolve('MDe')
      Eq students.size, 1
      Eq students[0].fullname, "Milena De Silva"
    end
    D "Finds the two matches for AKirk and AK" do
      students = @schoolclass.resolve('AKirk')
      Eq students.size, 2
      Eq students[0].fullname, "Anna Kirkby"
      Eq students[1].fullname, "Angela Kirkby"
      students = @schoolclass.resolve('AK')
      Eq students.size, 2
      Eq students[0].fullname, "Anna Kirkby"
      Eq students[1].fullname, "Angela Kirkby"
    end
    D "Can resolve surname fragment 'Jia'" do
      students = @schoolclass.resolve('Jia')
      Eq students.size, 1
      Eq students[0].fullname, "Linda Jiang"
    end
    D "Finds nobody named Foobar or FooBar" do
      students = @schoolclass.resolve('Foobar')
      T students.empty?
      students = @schoolclass.resolve('FooBar')
      T students.empty?
    end
    D "Raises SRError when given invalid fragments" do
      E(SR::SRError) { @schoolclass.resolve('Foo Bar') }
      E(SR::SRError) { @schoolclass.resolve('ABC') }
      E(SR::SRError) { @schoolclass.resolve('AxBxCx') }
      E(SR::SRError) { @schoolclass.resolve('Abbie5Leng') }
      E(SR::SRError) { @schoolclass.resolve('emma') }
    end
  end
  D "#resolve!" do
    D "Returns a Student, not an array" do
      student = @schoolclass.resolve!('Jia')
      Ko student, SR::DO::Student
      Eq student.fullname, "Linda Jiang"
    end
    D "Raises SRError when no match is found" do
      E(SR::SRError) { @schoolclass.resolve!('Emma') }
    end
  end
end
