// Requests are shown in a modal dialog, which is mostly taken
// care of by the generic ajax-modal plugin.

// But we need to take care of redirecting users to login
// (not in a modal) if not yet logged in, and then opening
// up the request modal when they come back after logging in.

// We'll do it by catching the loaded event from the ajax-modal.

//= require 'blacklight/blacklight'

Blacklight.onLoad(function() {

  $("body #blacklight-modal").on("loaded.blacklight.blacklight-modal", function(event) {
    var force_login = $(this).find("[data-force-login]");
    if (force_login.length > 0) {
      event.preventDefault();

      // redirect them to url given in the data-force-login
      var login_url   = force_login.data("forceLogin");
      var request_path = force_login.data("requestPath")


      // We need to send a 'referer' param that encodes the current request,
      // so when they come back, they'll get the modal again. This is really
      // hacky design, probably a better way of doing this.
      var redirect_url = login_url +
                      '?referer=' +
                      escape( document.location.href.split("#")[0] ) +
                      escape('#' + request_path);

      document.location.href = redirect_url;
    }
  });

    //parseuri function taken from http://blog.stevenlevithan.com/archives/parseuri
  // parseUri 1.2.2
  // (c) Steven Levithan <stevenlevithan.com>
  // MIT License

  function parseUri (str) {
    var o   = parseUri.options,
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

  function triggerPopupFromUrl() {
    // Do we have an #anchor telling us to automatically open a request?
    var fragmentId = window.location.hash;
    var request_path = parseUri(fragmentId.slice(1))['path'];

    var needsPopup = request_path && ['request', 'sms', 'email'].some(function (v) {
        return request_path.indexOf(v) >= 0;
    });

    if (needsPopup) {
        $("a[data-blacklight-modal='trigger'][href*='" + request_path + "']").trigger("click");
        return false;
    }
  }

  // on page load
  triggerPopupFromUrl();

  // and for the stackview, when a new item is loaded in.
  $("body").on("stackview-item-load", function(event) {
    // triggerRequestFromUrl();
  });


});
