# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'spec'
require 'spec/rake/spectask'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "spec/spec.opts"]
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,/*ruby*,']
end

require 'jeweler'
# Fix for Jeweler to use stable branch
class Jeweler
  module Commands
    class ReleaseToGit
      def run
        unless clean_staging_area?
          system "git status"
          raise "Unclean staging area! Be sure to commit or .gitignore everything first. See `git status` above."
        end
        repo.checkout('stable')
        repo.push('origin', 'stable')
        if release_not_tagged?
          output.puts "Tagging #{release_tag}"
          repo.add_tag(release_tag)
          output.puts "Pushing #{release_tag} to origin"
          repo.push('origin', release_tag)
        end
      end
    end
    class ReleaseGemspec
      def run
        unless clean_staging_area?
          system "git status"
          raise "Unclean staging area! Be sure to commit or .gitignore everything first. See `git status` above."
        end
        repo.checkout('stable')
        regenerate_gemspec!
        commit_gemspec! if gemspec_changed?
        output.puts "Pushing stable to origin"
        repo.push('origin', 'stable')
      end
    end
  end
end

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "amee-data-abstraction"
  gem.homepage = "http://github.com/AMEE/amee-data-abstraction"
  gem.license = "BSD 3-Clause"
  gem.summary = %Q{Calculation and form building tool hiding details of AMEEconnect}
  gem.description = %Q{Part of the AMEEappkit this gem provides a data abstraction layer, decreasing the amount and detail of development required}
  gem.email = "help@amee.com"
  gem.authors = ["James Hetherington", "Andrew Berkeley", "James Smith", "George Palmer"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "amee-data-abstraction #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end