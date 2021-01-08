# Add in our local 956 marc fields, which are to be treated JUST LIKE 856 marc
# fields, to the standard config from MarcDisplay plugin. We use 956 for certain
# local URLs not in the 856 for shared records. 
links_config = MarcDisplay.default_presenter_config_list.find { |hash| hash[:id] == :links}
links_config[:source] << "956uzy3"

# Turn forced hidden display on for certain fields, so Umlaut can fill
# them with js if needed.
MarcDisplay.default_presenter_config_list.find_all {|h| [:contents, :summary].include?(h[:id])}.each {|h| h[:display_on_empty] = :hidden}
MarcDisplay.default_presenter_config_list.find {|h| h[:id] ==:links}[:display_on_empty] = true


# Okay, we actually split the master list into several parts, to put them in
# different parts of the screen.

JHConfig.params[:main_presenter_list] = MarcDisplay.default_presenter_config_list.clone

fulltext = JHConfig.params[:main_presenter_list].find {|h| h[:id] == :links}
JHConfig.params[:main_presenter_list].delete(fulltext)

JHConfig.params[:links_presenter] = [fulltext] 

