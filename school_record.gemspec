# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "school_record/version"

Gem::Specification.new do |s|
  s.name        = "school_record"
  s.version     = SchoolRecord::VERSION
  s.authors     = ["Gavin Sinclair"]
  s.email       = ["gsinclair@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Records and reports on daily activities with a set of high-school classes.}
  s.description = %q{Records and reports on daily activities with a set of high-school classes. Written to meet the specific needs of the author!}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler"
  s.add_development_dependency "whitestone"
  
  s.add_runtime_dependency "col"
end
