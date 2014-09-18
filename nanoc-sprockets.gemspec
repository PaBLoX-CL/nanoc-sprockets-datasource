# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nanoc/sprockets/version'

Gem::Specification.new do |spec|
  spec.name          = "nanoc-sprockets"
  spec.version       = Nanoc::Sprockets::VERSION
  spec.authors       = ["François de Metz", "Pablo Olmos de Aguilera C."]
  spec.email         = ["francois@2metz.fr", "pablo@glatelier.org"]
  spec.description   = "Provides :sprockets as a datasource for nanoc. A Ruby library for compiling and serving web assets."
  spec.summary       = "Use sprockets as a datasource for nanoc."
  spec.homepage      = "https://github.com/PaBLoX-CL/nanoc-sprockets-datasource"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nanoc",               ">= 3.6.7", "< 4.0.0"
  spec.add_dependency "sprockets",           ">= 2.0"
  spec.add_dependency "sprockets-helpers",   "~> 1.1.0"

  spec.add_development_dependency  "rake",   "~> 10.0"
  spec.add_development_dependency  "rspec",  "~> 3.0"

  spec.add_development_dependency  "uglifier"
  spec.add_development_dependency  "sass"
end
