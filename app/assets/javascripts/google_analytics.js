// Some custom tracking

jQuery(document).ready(function($) {

	$(document).on("submit", "form.sms", function() {
		_gaq.push(['_trackEvent', 'Catalyst', 'SMS', 'Submit']);
	});

	$(document).on("submit", "form.per_page", function() {
		_gaq.push(['_trackEvent', 'Catalyst', 'Per-page Change', $("select#per_page option:selected").text()]);
	});

	$(document).on("submit", "form#sort_form", function() {
		_gaq.push(['_trackEvent', 'Catalyst', 'Sort Change', $("select#sort option:selected").text()]);
	});

	$(document).on("submit", "div#search form", function() {
		var search = "";

		if ($("#q").val()) {
			switch($("#search_field").val()) {
				case 'all_fields': search = "Any Field"; break;
				case 'title': search = "Title"; break;
				case 'author': search = "Author"; break;
				case 'subject': search = "Subject"; break;
				case 'number': search = "Numbers"; break;
				case 'advanced': search = "Advanced"; break;
			}

			search = search + ": " + $("#q").val() + ", ";
		}

		$(".filterName").each(function(index) {
			search = search + $(this).text() + ": " + $(this).next().text() + ", ";
		});
		search = search.substring(0,search.length-2);
		_gaq.push(['_trackEvent', 'Catalyst', 'Search', search]);
	});


    /* MULTI_SEARCH

       Google Analytics record clicks on Articles item titles and Find It
       links (which both go outside of our app so would not be caught by GA
       ordinarily). We recording using BOTH an 'event' and a 'virtual page
       view', cause we aren't sure which is best for capturing what we want,
       trying both.

       virtual page view recorded regardless of whether it's on two-column
       view or one-column articles only view. event we're trying to record only
       on multi-view. */

       $(".articles .bento_item_title a").on("click", function() {
       	_gaq.push(['_trackPageview', '/ga_virtual_page/article/title-link']);

           // Event only if we're on main multi-search page
           if ($(this).closest(".multi").size() > 0) {
           	_gaq.push(['_trackEvent', 'MultiSearch', 'title-link']);
           }
         });
       $(".articles .bento_item_other_links a.refworks").on("click", function() {
       	_gaq.push(['_trackPageview', '/ga_virtual_page/article/refworks-link']);
           // Event only if we're on main multi-search page
           if ($(this).closest(".multi").size() > 0) {
           	_gaq.push(['_trackEvent', 'MultiSearch', 'refworks-link']);
           }
         });
       $(".articles .bento_item_other_links a.openurl").on("click", function() {
       	_gaq.push(['_trackPageview', '/ga_virtual_page/article/openurl-link']);
           // Event only if we're on main multi-search page
           if ($(this).closest(".multi").size() > 0) {
           	_gaq.push(['_trackEvent', 'MultiSearch', 'openurl-link']);
           }
         });

       /* And we do virtual page views on the articles 'more options' links
          too. This will help us track how people LEAVE the article search pages,
          both two-column multi-search, and article-only search */
    $(".article_search_options .google_scholar").on("click", function() {
    	_gaq.push(['_trackPageview', '/ga_virtual_page/article/more_option_scholar']);
    });

    $(".article_search_options .db_dir").on("click", function() {
    	_gaq.push(['_trackPageview', '/ga_virtual_page/article/more_option_db_dir']);
    });

    $(".article_search_options .findit").on("click", function() {
    	_gaq.push(['_trackPageview', '/ga_virtual_page/article/more_option_findit']);
    });


  /* SPELL Custom event tracking of present a spell suggest, and click
     on a spell suggest, so we can measure how much it's being used. */
	$(".dym_suggest").each(function() {
		_gaq.push(['_trackEvent', 'spell_suggest', 'present_suggestion', $(this).text(), true ]);
	});

	$(".dym_suggest a").on("click", function() {
		_gaq.push(['_trackEvent', 'spell_suggest', 'click_on_suggestion', $(this).text(), true ]);
	});

});