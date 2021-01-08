// RMST info on items at LCS, for staff use.
// Add a link to bottom of page that toggles rmst to be visible or not
// link sets a cookie so 'show rmst' is persistent choice across pages

//= require blacklight/blacklight


// functions outside of closure, cause has_rmst_cookie() used in other places
function has_rmst_cookie() {
  return (document.cookie.indexOf("rmst=") != -1);
}
function toggle_rmst_cookie() {
  if (has_rmst_cookie()) {
    document.cookie = "rmst=true; expires=Thu, 01-Jan-1970 00:00:01 GMT; path=/";
  } else {
    document.cookie ="rmst=true; path=/"
  }
}


Blacklight.onLoad(function() {


  // only if we're on a page that has .holdings, add
  // link to footer
  if ($(".holdings").length > 0) {
    $(".footer .container ul.navbar-nav").append("<li class='nav-item navbar-toggle-li'/>");
    $("<a id='rmst-toggle' class='nav-link'>Show staff info</a>").appendTo("li.navbar-toggle-li").click(function() {
       toggle_rmst_cookie();

      $(".rmst").toggle( has_rmst_cookie() );

       if (has_rmst_cookie()) {
         $(this).text("Hide staff info");
       } else {
         $(this).text("Show staff info");
       }
    });

    if (has_rmst_cookie()) {
       $(".rmst").show();
       $("#rmst-toggle").text("Hide staff info");
     }
  }
});
