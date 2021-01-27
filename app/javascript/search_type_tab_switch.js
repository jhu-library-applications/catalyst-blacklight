// When user chooses a tab to change 'search type' (Catalog, Articles, etc)
// ... we want to preserve any entered but not submitted search text in the
// text input, make it look like a tab switch even though it's a submit. 

//= require blacklight/blacklight


Blacklight.onLoad(function() {

	//parseuri function taken from http://blog.stevenlevithan.com/archives/parseuri
	// parseUri 1.2.2
	// (c) Steven Levithan <stevenlevithan.com>
	// MIT License

	function parseUri (str) {
		var	o   = parseUri.options,
			m   = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
			uri = {},
			i   = 14;

		while (i--) uri[o.key[i]] = m[i] || "";

		uri[o.q.name] = {};
		uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
			if ($1) uri[o.q.name][$1] = $2;
		});

		return uri;
	};

	parseUri.options = {
		strictMode: false,
		key: ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],
		q:   {
			name:   "queryKey",
			parser: /(?:^|&)([^&=]*)=?([^&]*)/g
		},
		parser: {
			strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
			loose:  /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
		}
	};



	$(".search-navbar").on("click", "[data-preserve-search-context=true] a", function(event) {		
		var entry = $("#q").val();
		var field = $("#search_field").val();

		if ( (typeof(entry) !== "undefined") && entry.length > 0 ) {

			url = parseUri( $(this).attr("href") );
			url.queryKey.q 						= entry;
			url.queryKey.search_field = field;

			$(this).attr('href',   url.path + "?" + $.param(url.queryKey) );
		}
	});


});
