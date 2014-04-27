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
  spec.license       = 'MIT'

  spec.files         = []
  spec.executables   = ["series_calc"]
  spec.require_paths = ["lib"]

  spec.add_dependency "timeseries", "~> 1.0"
  spec.add_dependency "logging", "~> 1.8.2"
  spec.add_development_dependency "bundler", "~> 1.3"
end
