require 'bundler/gem_tasks'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'

desc 'Default: run unit tests.'
task :default => [:test_compatibility, :test_noncompatibility]

desc 'Test the userstamp plugin.'
Rake::TestTask.new(:test_noncompatibility) do |t|
  # Run only compatibility = false tests
  t.libs << 'lib'
  all_tests = FileList['test/**/*_test.rb']
  all_tests.reject! { |x| x =~ /\/compatibility_/ }
  t.test_files = all_tests
  t.verbose = true
end

Rake::TestTask.new(:test_compatibility) do |t|
  # Run only compatibility = true tests
  t.libs << 'lib'
  t.pattern = 'test/**/compatibility_*_test.rb'
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
