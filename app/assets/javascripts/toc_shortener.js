/* Look at table of contents listing on #show page, if it's really
   long, shorten it with a 'show more' type link.

   Some ToCs are literally hundreds of lines long, and make it
   hard to see what's below em on the page.

   First pass at this. Our ToC's are generally html <ul>s.
*/

//= require blacklight/blacklight

Blacklight.toc_shortener = {
  "shorten_threshold_count":  12,
  "shorten_to_count":         8,
  "show_more_text":           "Show %s more lines…"

}

Blacklight.onLoad(function() {
  $("ul.contents505").each(function(index, ul) {
    ul = $(ul);
    if (ul.find("li").length > Blacklight.toc_shortener.shorten_threshold_count) {
      ul.find("li:gt("+ (Blacklight.toc_shortener.shorten_to_count - 1)  +")").hide().addClass("shortener-hidden");

      var btn_label = Blacklight.toc_shortener.show_more_text.replace("%s", ul.find("li").length - Blacklight.toc_shortener.shorten_to_count);

      ul.find("li:eq(" + Blacklight.toc_shortener.shorten_to_count + ")").after(
        "<li><button type='button' class='btn btn-default' data-toc-shortener='show-more'>" +
        btn_label +
        "</button></li>"
      );

      ul.on("click", "[data-toc-shortener=show-more]", function(event) {
        ul.find("li.shortener-hidden").removeClass("shortener-hidden").show();
        $(event.target).remove();
      });
    }
  });
});
