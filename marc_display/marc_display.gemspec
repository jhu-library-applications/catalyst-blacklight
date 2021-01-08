##
# marc_display used to be isolated as a rails 'plugin' in vendor/plugins,
# because the idea was eventually it might become a gem.
#
# it'll probably never become a gem at this point, it's gotten kinda hacky
# and I think I'd rewrite it with what I know now to be different. 
#
# But vendor/plugins aren't supported in RAils anymore, so we move
# it to look like a gem, with a gemspec, but be checked into main
# catalyst repo. 
#
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "marc_display"
  s.version     = "0.1.0"
  s.authors     = ["Jonathan Rochkind"]
  s.email       = ["rochkind@jhu.edu"]  
  s.summary     = "marc mapping for display"

  s.files = Dir["{app,config,db,lib}/**/*"]
  s.test_files = Dir["spec/**/*"]  
  
end
