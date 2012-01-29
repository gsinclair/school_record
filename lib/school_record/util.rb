
class Object
  # Why oh why is this not in the language?
  def in?(collection)
    collection.include? self
  end
end

module SchoolRecord
  class Util
    # Returs a string like "13 Jan" or " 2 Mar" (note blank padding).
    def Util.day_month(date)
      date.strftime("%e %b")
    end
  end
end
