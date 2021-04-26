$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "blacklight_folders/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "blacklight_folders"
  s.version     = "2.0.0"
  s.authors     = ["Jon Fackrell"]
  s.email       = ["jon.fackrell@jhu.edu"]
  s.homepage    = "https://github.com/curationexperts/blacklight_folders"
  s.summary     = "Organized bookmarks for Blacklight"
  s.description = "Organized bookmarks for Blacklight"
  s.license     = "See LICENSE file"

  s.files = Dir["{app,config,db,lib,bin,vendor}/**/*", "LICENSE", "Rakefile", "README.rdoc"]
  s.add_dependency "rails", ">= 4.0.1", "< 6"
  s.add_dependency "acts_as_list", ">= 0.4.0"
  s.add_dependency "blacklight", ">= 5.16.4", "< 8"
  s.add_dependency "cancancan", "~> 3.2"
  s.add_dependency 'select2-rails', '~> 4.0'

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "jettywrapper"
  s.add_development_dependency "rspec-rails", "~> 3.0"
  s.add_development_dependency "factory_girl"
  s.add_development_dependency "engine_cart", "~> 0.4.0"
  s.add_development_dependency "capybara"
end
