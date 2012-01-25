module SchoolRecord
  version_path = File.expand_path("../../../VERSION.txt", __FILE__)
  VERSION = File.read(version_path).strip
end
