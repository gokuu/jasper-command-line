# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "jasper-command-line/version"

Gem::Specification.new do |s|
  s.name        = "jasper-command-line"
  s.version     = JasperCommandLine::VERSION
  s.authors     = ["Pedro Rodrigues"]
  s.email       = ["pedro@bbde.org"]
  s.homepage    = "http://github.com/gokuu/jasper-command-line"
  s.summary     = "Use jasper-rails from the command line."
  s.description = "Use jasper-rails from the command line."

  s.add_dependency('rjb', '>= 1.4.0')
  s.add_dependency('builder', '>= 3.0.3')
  s.add_dependency('activesupport', '>= 3.2.0')
  s.add_dependency('pdf-merger', '>= 0.3.1')
  s.add_development_dependency("rspec", "~> 2.7")
  s.add_development_dependency("rake", "~> 0.9.2")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
