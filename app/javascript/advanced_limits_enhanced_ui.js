// add fancy combo box UI to advanced search form facet limits, using
// chosen or select2 or whatever, assume they are loaded. 
//
Blacklight.onLoad(function() {
  $(".advanced-search-facet-select").chosen({width: "100%"})
});

