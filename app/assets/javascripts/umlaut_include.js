/*
 * Use blacklights Blacklight.onLoad
 * require blacklight/blacklight
 *
 * This file uses the Umlaut JQuery Content Utility to embed Find It
 * content on catalyst pages:
 *   * The item detail page, where a variety of content is embedded
 *   * The request panel, both as a modal and as a separate page,
 *     where BorrowDirect section is embedded.
 *
 * https://github.com/team-umlaut/umlaut/wiki/JQuery-Content-Utility
 */

Blacklight.onLoad(function(){


  //Pass in a 'dd' element, will "show" both it and it's
  //corresponding 'dt' element. We use it to show hidden dd/dt combos
  // on item detail page, when we have Umlaut content for them.
  function show_dt_dd(element) {
    var dd = $(element).closest("dd");
    dd.show();
    dd.prev("dt").show();
  }

  function replace_links_with_umlaut(html) {
    // Make sure the 'links' section is shown
    $(".links").show();

    // Change heading to heading from Umlaut.
    var original_heading = $(html).find(".section_heading").remove().text();
    if (original_heading != "") {
      $(".links").find("[data-umlaut-update=heading]").text(original_heading);
    }
    //Hide the spinner, cause now we've got our own.
    $(html).closest(".links").find(".umlaut_load_msg").hide();
    // Hide any BL-straight-from-marc links.
    if ($(".umlaut:contains('Finding aid from')").length > 0) {
      $(html).closest(".links").find(".marc856").hide();
      // Update label before finding aid url
      $("a.response_link:contains('Finding aid from')").each(function() {
        var text = $(this).text();
        text = text.replace("Finding aid from", "Collection guide available:");
        $(this).text(text);
      });
    } else {
      $(html).closest(".links").find(".marc856").find('.marc856*:not(:contains("Finding aid")):not(:contains("Finding Aid")):not(:contains("Complete inventory")):not(:contains("Collection guide available"))').closest('li.marc856').hide();
      if ($(html).closest(".links").find(".marc856*:contains('Finding aid'),.marc856*:contains('Finding Aid'),.marc856*:contains('Complete inventory')").length > 0) {
        $('p.umlaut-unavailable').hide();
        // Update label before finding aid url
        $(".marcLine.marc856*:contains('Finding aid'),.marcLine.marc856*:contains('Finding Aid'),.marcLine.marc856*:contains('Complete inventory')").each(function() {
          $(this).find('span').first().text("Collection guide available:");
        })
      }
    }

    if ($("#hathi-etas").attr("hathi-present").trim() == "true"){
        $('p.umlaut-unavailable').hide();
    }
  }


  /* JQuery Content Utility Section Target Configuration
   *
   * We define all our sections in an array here, so we can
   * more easily re-use them for both the full page updater, and
   * the request modal updater.
   */

  var section_targets = []

  section_targets.push({
    umlaut_section_id: "cover_image",
    selector: ".cover-image-container"
  });

  section_targets.push({
    umlaut_section_id: "fulltext", selector:".links [data-umlaut-update=body]" , position: "prepend",
    after_update: function(html, count, section_target) {
      if (count != 0) {
        replace_links_with_umlaut(html);
      }
      else {
        $(html).hide();
      }
    },
    complete: function(target_obj) {
      // On complete, replace static with umlaut content even
      // if there are no hits, to show 'not available' message.
      $(target_obj.host_div_element).show();
      replace_links_with_umlaut(target_obj.host_div_element);
    }
  });

  section_targets.push({
    umlaut_section_id: "borrow_direct",
    selector:".card.umlaut.borrow_direct *[data-umlaut-bd-content]",
    before_update: function(html, count, section_target) {
      // Only replace our existing content if we have new content (todo or are complete)
      if (count === 0) {
        return false;
      }

      // Remove our preloaded content, since we have content
      // from umlaut
      section_target.container.find(".card.borrow_direct *[data-umlaut-bd-preload-content]").hide();

      html = $(html);
      // Remove the heading, we already have one on-page
      // $("*[data-umlaut-bd-content]").closest('.card.umlaut.borrow_direct').find('.card-title').text(  html.find(".section_heading h3").remove().text()  );

      // Remove the section prompt, and add it to the heading, bootstrap style
      prompt = $(html).find(".section_prompt").remove();
      // if (prompt.length > 0) {
      //   $("*[data-umlaut-bd-content]").closest('.card.umlaut.borrow_direct').find('.card-title').append("<small>" + prompt.text() + "</small>")
      // }

      // Make the check bd link a bootstrap small button, to match design
      // used for Catalyst request links
      html.find(".bd-direct-link .response_link").addClass("btn btn-primary btn-sm");

      // Add our redirect link to Umlaut form, so Umlaut will send us back
      // to current page after making a request. If we are in a request modal,
      // we add the special anchor data that will tell Catalyst to open up
      // the request modal again on return.
      var returnUrl = window.location.href;
      if (section_target.container.attr("data-request-path")) {
        returnUrl = returnUrl.replace(/\#.*$/, '');
        returnUrl += "#" + section_target.container.attr("data-request-path");
      }
      html.find("input.borrow-direct-form-redirect").attr("value", returnUrl)

      return true;
    }
  });

  section_targets.push({
    umlaut_section_id: "excerpts",
    selector:".card.umlaut.excerpts .card-body",
    before_update: function(html, count) {
      $('.card.umlaut.excerpts .card-title').text(  $(html).find(".section_heading h3").remove().text()  );
      return ( count != 0);
    },
    after_update: function(html, count) {
      if (count != 0) {
        $(".card.umlaut.excerpts").show();
      }
    }
  });

  section_targets.push({
    umlaut_section_id: "highlighted_link",
    selector:".card.umlaut.highlighted_link .card-body",
    before_update: function(html, count, section_target) {
      section_target.container.find('.card.umlaut.highlighted_link .card-title').text(  $(html).find(".section_heading h3").remove().text()  );
      return ( count != 0);
    },
    after_update: function(html, count) {
      if (count != 0) {
        $('.card.umlaut.highlighted_link').show();
      }
    }
  });

  section_targets.push({
    umlaut_section_id: "search_inside",
    selector:".card.umlaut.search_inside .card-body",
    before_update: function(html, count, section_target) {
      //$(html).find("form").addClass("form-inline");
      //$(html).find("input, select").addClass("form-control");
      section_target.container.find('.card.umlaut.search_inside .card-title').text(  $(html).find(".section_heading h3").remove().text()  );
      return (count != 0);

    },
    after_update: function(html, count) {
      if (count != 0) {
        $('.card.umlaut.search_inside').show();
      }
      // alter classes to display how we want, in bootstrap3

      // turn text input and search button into an input group, with search
      // button having just an icon in it.
      var new_btn = '<button type="submit" class="btn btn-primary search-inside-btn" id="search">';
      new_btn    += '  <span class="sr-only">Search</span>';
      new_btn    += '  <span class="glyphicon glyphicon-search"></span>';
      new_btn    += '</button>';
      $(html).find(".search-inside-query input[type=submit]").wrap().replaceWith(new_btn);
      $(html).find(".search-inside-query input[type=text]").addClass("form-control");
      $(html).find('.search-inside-query span.input-group-btn').addClass('input-group-append')
      $(html).find(".search-inside-query").removeClass("input-append").addClass("input-group")

      // and the sources section, style select menu, yeah we're not scared to
      // cheesily add inline styles -- width auto again to prevent full width,
      // and some margin.
      $(html).find(".search-inside-source select").addClass("form-control")
        .css("width", "auto")
        .css("display", "inline-block");
      $(html).find(".search-inside-source").css("padding-bottom", "10px");
    }
  });

  section_targets.push({
    umlaut_section_id: "abstract",
    selector:"dd.summary",
    position: "append",
    before_update: function(html) {
      $(html).find(".section_heading").remove();
    },
    after_update: function(html, count) {
      if (count != 0) {
        show_dt_dd(html);
      }
    }
  });

  section_targets.push({
    umlaut_section_id: "table_of_contents",
    selector:"dd.contents",
    position: "append",
    before_update: function(html) {
      $(html).find(".section_heading").remove();
    },
    after_update: function(html, count) {
      if (count != 0) {
        if ($(html).prev("ul .marcLinePart").length > 0) {
          $(html).css("margin-top", "1.5em");
        }
        show_dt_dd(html);
      }
    }
  });



  // Get Umlaut update_html.js URL from <link> element in head
  var umlautIncludeUrl = $("link[name~=data-umlaut-update-html-link]").attr("href");
  // strip out any http or https to get a protocol-relative URL,
  // that will be appropriate for http or https page to avoid mixed content
  // warnings
  if (umlautIncludeUrl) {
    umlautIncludeUrl = umlautIncludeUrl.replace(/^https?\:/, '');
  }

  // Load the Umlaut helper script asynchronously here, so it won't slow
  // down Catalyst page load -- even if Umlaut is down or responding slowly.
  $.getScript(umlautIncludeUrl, function() {

    // Expand-contract sections from Umlaut already have data-* attributes
    // for Bootstrap collapsible, but we need to disable their actual href's too --
    // and add some custom behavior to change icon/label
    $(document).on("click", ".umlaut_section_content [data-toggle=collapse]", function(event) {
      event.preventDefault();
    });
    $(document).on("show.bs.collapse", ".umlaut_section_content .collapse", function(event) {
        // Update the icon
        $(this).parent().find('.collapse-toggle i').removeClass("umlaut_icons-list-closed").addClass("umlaut_icons-list-open");
        // Update the action label
        $(this).parent().find(".expand_contract_action_label").text("Hide ");
    });
    $(document).on("hide.bs.collapse", ".umlaut_section_content .in", function(event) {
        // Update the icon
        $(this).parent().find('.collapse-toggle i').removeClass("umlaut_icons-list-open").addClass("umlaut_icons-list-closed");
        // Update the action label
        $(this).parent().find(".expand_contract_action_label").text("Show ");

    });


    // Are we on an item detail page, with an OpenURL? Umlautify it!
    // This also applies to the Request page when NOT shown in a modal, but
    // just a page of it's own -- it also has an a.findit_link, and we can use
    // the same logic to update with Umlaut content, although it'll only have
    // a slot on the page for BorrowDirect stuff.
    var openurl_link = $("a.findit_link");
    if (openurl_link.length > 0 ) {
        var openurl = openurl_link.attr("href");
        var ctx_object_kev = openurl.substring( openurl.indexOf("?") + 1);
        var umlaut_base = openurl.substring(0, openurl.indexOf("/resolve"));

        /* Set up our updater sections */
        var updater = new Umlaut.HtmlUpdater({
          "umlaut_base": umlaut_base,
          "context_object": ctx_object_kev,
          "container": ".container"
        });


        // Create a place for 'excerpts', 'see also', 'search inside' to live
        $('section.page-sidebar').append('<div class="card card-default umlaut highlighted_link mt-4" style="display:none"><div class="card-header"><h3 class="card-title h6 mb-0">See Also</h3></div><div class="card-body"></div>');
        $('section.page-sidebar').append('<div class="card card-default umlaut excerpts mt-4" style="display:none"><div class="card-header"><h3 class="card-title h6 mb-0">Limited Excerpts</h3></div><div class="card-body"></div>');
        $('section.page-sidebar').append('<div class="card card-default umlaut search_inside mt-4" style="display:none"><div class="card-header"><h3 class="card-title h6 mb-0">Search Inside</h3></div><div class="card-body"></div>');


        // move the openurl link to bottom of sidebar
        $("section.page-sidebar").append( openurl_link );

        /* Add a progress spinner to the existing static links section. */
        var spinner = '<span class="umlaut_load_msg"><img src="' + umlaut_base + '/assets/spinner.gif" border="0"/> Loading more</span>';
        $(".links .card-body").append(spinner);

        /* And to the sidebar */
         $("section.page-sidebar").append(spinner);


        /* Add a progress spinner to the preloaded BD area immediately */
        var spinner = '<span class="umlaut_load_msg"><img src="' + umlaut_base + '/assets/spinner.gif" border="0"/></span>';
        $(".card.borrow_direct *[data-umlaut-bd-preload-content]").append(spinner);

        // add all our section targets
        $.each(section_targets, function(index, section_target) {
          updater.add_section_target(section_target);
        });


        /* Final callback for removing progress spinner */
        updater.complete = function() {
          $(".umlaut_load_msg").remove();
        }

        /* Call */

        updater.update();
      }


    });


    // Adding embedded umlaut content in the BorrowDirect area on request
    // screens is harder.
    // First we'll catch the modal open, and add umlaut if it's got the BD
    // holding area.
    $(document).on("loaded.blacklight.ajax-modal", function(event) {
      // If we are loading a request form in our panel, with a borrow direct
      // area, that has an OpenURL -- use Umlaut to load BD API info in dynamically.
      var umlaut_link = $(event.target).find("*[data-borrow-direct-umlaut-wrapper] a.findit_link");
      if (umlaut_link.length > 0) {
        var openurl_link = umlaut_link.attr("href");
        var ctx_object_kev = openurl_link.substring( openurl_link.indexOf("?") + 1);
        var umlaut_base = openurl_link.substring(0, openurl_link.indexOf("/resolve"));

        var container = umlaut_link.closest("[data-borrow-direct-umlaut-wrapper]");

        /* Add a progress spinner to the preloaded BD area immediately */
        var spinner = '<span class="umlaut_load_msg"><img src="' + umlaut_base + '/assets/spinner.gif" border="0"/></span>';
        $(event.target).find(".card.borrow_direct *[data-umlaut-bd-preload-content]").append(spinner);

        var updater = new Umlaut.HtmlUpdater({
          'umlaut_base': umlaut_base,
          'context_object':     ctx_object_kev,
          'container':   container
        });

        // Just the borrow_direct section from our section_targets array.
        var bd_section = $.grep(section_targets, function(item) {
          return item.umlaut_section_id == "borrow_direct";
        })[0];
        if (bd_section) {
          updater.add_section_target(bd_section);
        }

        updater.update();
      }
    });


});
