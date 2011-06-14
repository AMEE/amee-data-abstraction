require './lib/amee-data-abstraction/version.rb'
require 'rake'

Gem::Specification.new do |s|
  s.name = "amee-data-abstraction"
  s.version = AMEE::DataAbstraction::VERSION::STRING
  s.date = "2011-05-25"
  s.summary = "Calculation and form building tool hiding details of AMEE API"
  s.email = "help@amee.com"
  s.homepage = "http://github.com/AMEE/data-abstraction"
  s.has_rdoc = true
  s.authors = ["James Hetherington"]
  s.files = ["README", "COPYING", "CHANGELOG"]
  s.files += FileList.new('lib/**/*.rb')
  s.files += ['init.rb', 'rails/init.rb']
  s.files += [] #bin/executable
  s.files += FileList.new('examples/**/*.rb')
  s.files += ['init.rb', 'rails/init.rb']
  s.executables = []
  s.add_dependency("amee", ">= 2.6.0", "< 3.0")
  s.add_dependency("amee-internal", ">= 3.7.2", "< 4.0")
  s.add_dependency("uuidtools")
  s.add_dependency("quantify", "1.0.0")
end
