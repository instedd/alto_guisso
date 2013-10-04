# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guisso/version'

Gem::Specification.new do |spec|
  spec.name          = "alto_guisso"
  spec.version       = Guisso::VERSION
  spec.authors       = ["Ary Borenszweig", "Juan Wajnerman"]
  spec.email         = ["aborenszweig@manas.com.ar", "jwajnerman@manas.com.ar"]
  spec.description   = %q{Use Guisso}
  spec.summary       = %q{Alto Guisso allows connecting your application with Guisso (Instedd's Single Sign On)}
  spec.homepage      = "https://bitbucket.org/instedd/alto_guisso"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency("rails", ">= 3.0")
  spec.add_dependency("ruby-openid")
  spec.add_dependency("rack-oauth2")
  spec.add_dependency("omniauth")
  spec.add_dependency("omniauth-openid")

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
