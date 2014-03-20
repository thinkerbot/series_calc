# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'series_calc/version'

Gem::Specification.new do |spec|
  spec.name          = "series_calc"
  spec.version       = SeriesCalc::VERSION
  spec.authors       = ["Simon Chiang"]
  spec.email         = ["simon.a.chiang@gmail.com"]
  spec.description   = %q{Calculate a series}
  spec.summary       = %q{}

  spec.files         = []
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
end
