require 'rake'
require 'spec'
require 'spec/rake/spectask'
require 'rake/rdoctask'
require 'rubygems/specification'
require 'rake/gempackagetask'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "spec/spec.opts"]
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,/*ruby*,']
end

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "AMEE-Data-Abstraction - RDoc documentation"
  rdoc.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.rdoc_files.include('README', 'COPYING')
  rdoc.rdoc_files.include('lib/**/*.rb')
}

# Gem build task - load gemspec from file
gemspec = File.read('amee-data-abstraction.gemspec')
spec = eval("#{gemspec}")
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
end
