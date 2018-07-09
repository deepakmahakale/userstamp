require 'bundler/gem_tasks'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the userstamp plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  all_tests = FileList['test/**/*_test.rb']
  t.test_files = all_tests
  t.verbose = true
end

desc 'Generate documentation for the userstamp plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Userstamp'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README', 'CHANGELOG', 'LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
