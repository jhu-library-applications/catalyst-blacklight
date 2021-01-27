//= require blacklight/blacklight


Blacklight.onLoad(function() {


	// On clicks on our trigger, make sure the content has the collapsible
	// plugin, and toggle it.
	$("body").on("click", "ul:not(.expandable-disabled) [data-toggle=collapsible-holdings-trigger]", function(e) {
		// Only if it's not on an internal hyperlink, like the request button. 
		if (! $(e.target).is("a")) {
			e.preventDefault();

			var content = $(this).parent().find("[data-toggle=collapsible-holdings-content]").first();

			// add collapse plugin if it hasn't been added yet
			if (! content.data("bs.collapse")) {
				content.collapse({toggle: false});
			}

			content.collapse("toggle");
		}
	});	

	// on hidden/shown events, change the classes on our
	// trigger too, so it can be used to effect chevron icon display
	$('body').on('hide.bs.collapse', '[data-toggle=collapsible-holdings-content]', function (e) {
		var trigger = $(e.target).parent().find("[data-toggle=collapsible-holdings-trigger]").first();

		trigger.removeClass("in")
	});
	$('body').on('show.bs.collapse', function (e) {
		var trigger = $(e.target).parent().find("[data-toggle=collapsible-holdings-trigger]").first();

		trigger.addClass("in")
	});


});
