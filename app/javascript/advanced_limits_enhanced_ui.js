// add fancy combo box UI to advanced search form facet limits, using
// chosen or select2 or whatever, assume they are loaded. 
//
Blacklight.onLoad(function() {
  // Hide Online from format facet because it's really duplicated in Access facet
  $('#format option[value="Online"]').hide();

  $(".advanced-search-facet-select").chosen({width: "100%"});
});

