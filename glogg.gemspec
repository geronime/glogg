# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'glogg/version'

Gem::Specification.new do |s|
	s.name        = 'glogg'
	s.version     = GLogg::VERSION
	s.platform    = Gem::Platform::RUBY
	s.authors     = ['Jiri Nemecek']
	s.email       = ['nemecek.jiri@gmail.com']
	s.homepage    = ''
	s.summary     = %q{custom logging gem}
	s.description = %q{Another custom logging gem with multiple debug log levels.}

	s.rubyforge_project = 'glogg'

	s.files         = `git ls-files`.split("\n")
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
	s.require_paths = ['lib']

end

