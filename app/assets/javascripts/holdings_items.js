// Make link to 'items' for a copy-containing-items collapse/expand
// on-page items, instead of linking out to new page. 

//= require blacklight/blacklight

Blacklight.onLoad(function() {
  $("body").on("click", ".item-children-link", function(event) {
    link = $(this);

    event.preventDefault();

    var container  = link.closest(".item-children");
    var contents   = container.find(".item-children-collapse");

    if (contents.hasClass("reloadable")) {
      // eliminate it entirely and reload it!
      contents.remove();
      contents = [];
    }

    if (contents.length == 0) {
      // we need to add it, make it collapsible, and load it.

      contents = $($.parseHTML('<div class="item-children-collapse collapse">Loading...</div>')).appendTo(container).
        load(link.attr("href") + " div.holdings-drill-down", function(response, status, xhr) {
          //if server isn't available at all, for some reason
          //jquery still reports 'success', but with xhr.status 0
          if (status == "error" || xhr.status == 0) {         
            $(this).addClass("reloadable").html("<p class='alert alert-danger'>" +
              "Sorry, there has been an error: " + xhr.status + " " + (xhr.status != 0 ? xhr.statusText : "Network error") +
              "<br><a href='"+link.attr("href")+"'>"+link.attr("href")+"</a>" +
              "</p>"
              );
          }
          if (has_rmst_cookie()) {
            $(".rmst").show();          
          }
        }).collapse({toggle: false});
    }

    contents.collapse("toggle");
  });

  // on hidden/shown events, change the classes on our
  // trigger too, so it can be used to effect chevron icon display
  $('body').on('hide.bs.collapse', '.item-children-collapse', function (e) {
    var trigger = $(e.target).parent().find(".item-children-link").first();

    trigger.removeClass("in")
  });
  $('body').on('show.bs.collapse', '.item-children-collapse', function (e) {
    var trigger = $(e.target).parent().find(".item-children-link").first();

    trigger.addClass("in")
  });

});