# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{amee-data-abstraction}
  s.version = "2.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Hetherington", "Andrew Berkeley", "James Smith", "George Palmer"]
  s.date = %q{2011-10-12}
  s.description = %q{Part of the AMEEappkit this gem provides a data abstraction layer, decreasing the amount and detail of development required}
  s.email = %q{help@amee.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.txt"
  ]
  s.files = [
    ".rvmrc",
    "CHANGELOG.txt",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.txt",
    "Rakefile",
    "VERSION",
    "amee-data-abstraction.gemspec",
    "examples/_calculator_form.erb",
    "examples/calculation_controller.rb",
    "lib/amee-data-abstraction.rb",
    "lib/amee-data-abstraction/calculation.rb",
    "lib/amee-data-abstraction/calculation_set.rb",
    "lib/amee-data-abstraction/drill.rb",
    "lib/amee-data-abstraction/exceptions.rb",
    "lib/amee-data-abstraction/input.rb",
    "lib/amee-data-abstraction/metadatum.rb",
    "lib/amee-data-abstraction/ongoing_calculation.rb",
    "lib/amee-data-abstraction/output.rb",
    "lib/amee-data-abstraction/profile.rb",
    "lib/amee-data-abstraction/prototype_calculation.rb",
    "lib/amee-data-abstraction/term.rb",
    "lib/amee-data-abstraction/terms_list.rb",
    "lib/amee-data-abstraction/usage.rb",
    "lib/config/amee_units.rb",
    "lib/core-extensions/class.rb",
    "lib/core-extensions/hash.rb",
    "lib/core-extensions/ordered_hash.rb",
    "lib/core-extensions/proc.rb",
    "spec/amee-data-abstraction/calculation_set_spec.rb",
    "spec/amee-data-abstraction/calculation_spec.rb",
    "spec/amee-data-abstraction/drill_spec.rb",
    "spec/amee-data-abstraction/input_spec.rb",
    "spec/amee-data-abstraction/metadatum_spec.rb",
    "spec/amee-data-abstraction/ongoing_calculation_spec.rb",
    "spec/amee-data-abstraction/profile_spec.rb",
    "spec/amee-data-abstraction/prototype_calculation_spec.rb",
    "spec/amee-data-abstraction/term_spec.rb",
    "spec/amee-data-abstraction/terms_list_spec.rb",
    "spec/config/amee_units_spec.rb",
    "spec/core-extensions/class_spec.rb",
    "spec/core-extensions/hash_spec.rb",
    "spec/core-extensions/ordered_hash_spec.rb",
    "spec/core-extensions/proc_spec.rb",
    "spec/fixtures/electricity.rb",
    "spec/fixtures/electricity_and_transport.rb",
    "spec/fixtures/transport.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/AMEE/amee-data-abstraction}
  s.licenses = ["BSD 3-Clause"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{Calculation and form building tool hiding details of AMEEconnect}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<amee>, ["~> 4.1.5"])
      s.add_runtime_dependency(%q<uuidtools>, ["= 2.1.2"])
      s.add_runtime_dependency(%q<quantify>, ["~> 2.0.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rspec>, ["= 2.6.0"])
      s.add_development_dependency(%q<flexmock>, ["> 0.8.6"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, [">= 0"])
    else
      s.add_dependency(%q<amee>, ["~> 4.1.5"])
      s.add_dependency(%q<uuidtools>, ["= 2.1.2"])
      s.add_dependency(%q<quantify>, ["~> 2.0.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rspec>, ["= 2.6.0"])
      s.add_dependency(%q<flexmock>, ["> 0.8.6"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<rdoc>, [">= 0"])
    end
  else
    s.add_dependency(%q<amee>, ["~> 4.1.5"])
    s.add_dependency(%q<uuidtools>, ["= 2.1.2"])
    s.add_dependency(%q<quantify>, ["~> 2.0.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rspec>, ["= 2.6.0"])
    s.add_dependency(%q<flexmock>, ["> 0.8.6"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<rdoc>, [">= 0"])
  end
end

