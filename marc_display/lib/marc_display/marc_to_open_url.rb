require 'openurl'
require 'marc_display/open_url_default_mappings'

module MarcDisplay
  # Produces a decent (but not great) ruby OpenURL object out of a ruby Marc
  # object.  OpenURL will always be 'book' or 'journal'. Otherwise unrecognized
  # formats will be called "book".
  # "rft.genre" IS set to 'book' or 'journal' -- or sometimes 'unknown'.
  #
  # Future to-do, recognize Dissertations in Marc (Marc 502) or book chapters
  # or articles (marc 773 combined with leader 6/7), and set openurl
  # accordingly.
  #
  # * rft.au is taken from 1xx or 245c if no 1xx present.
  # * ISBN and ISSN are recognized and included.
  # * OCLCnum, LCCN, and DOI are found and included as URI's in rfr_id.
  #
  class MarcToOpenUrl
    include MarcDisplayLogic::MarcLogicProcs


    attr_accessor :marc, :mappings

    def initialize(aMarc = nil, a_mappings = nil)
      self.marc = aMarc
      self.mappings = a_mappings || MarcDisplay::OpenUrlDefaultMappings.produce!
    end

    def build_openurl
      return nil if marc.nil?


      ctx = OpenURL::ContextObject.new

      ctx.referent.set_format( self.openurl_format )
      ctx.referent.set_metadata('genre', openurl_genre  )

      # Author, have to look in two places, first try 1xx then 245c, which
      # will be lame.
      au_first_choice = build_presenter_from_key(:au_first_choice)
      if au_first_choice.lines.length > 0
        ctx.referent.set_metadata('au', au_first_choice.lines[0].join )
      else
        ctx.referent.set_metadata('au', build_and_get_first_line(:au_second_choice))
      end

      [:doi_uri, :oclcnum_uri, :lccn_uri].each do |key|
        if ( uri = build_and_get_first_line(key))
          ctx.referent.add_identifier( uri )
        end
      end

      # including date for what's really a journal messes up resolvers,
      # interpreted as an article date.
      unless (openurl_genre == "journal")
        ctx.referent.set_metadata('date', build_and_get_first_line(:date))
      end
      ctx.referent.set_metadata('issn', build_and_get_first_line(:issn))
      ctx.referent.set_metadata('isbn', build_and_get_first_line(:isbn))

      title_text = build_and_get_first_line(:title, ": ")

      if self.openurl_format == "book"
        # book-only ones
        ctx.referent.set_metadata('btitle', title_text)

        ctx.referent.set_metadata('place', build_and_get_first_line(:place))
        ctx.referent.set_metadata('pub', build_and_get_first_line(:pub))
        ctx.referent.set_metadata('edition', build_and_get_first_line(:edition))
        ctx.referent.set_metadata('tpages', build_and_get_first_line(:tpages))
      elsif self.openurl_format == "journal"
        #journal only
        ctx.referent.set_metadata("jtitle", title_text)
      end

      ctx
    end

    # if leader 07 is 's' or 'b', we're going to call this "journal" format.
    # otherwise, the catch-all "book" format. We can specify a BIT more later in
    # rft.genre
    def openurl_format
      if marc.leader.slice(7,1) == 's'
        "journal"
      else
        "book"
      end
    end



    # Figure out the proper rft.genre. Differs for
    # format 'book' vs 'journal'. Basically only comes
    # with 'book' or 'document' for book format,
    # and 'journal' or 'unknown' for journal format.
    # Other ones, too hard to tell from MARC, for now. Fine
    # tunings can come later.
    #
    # No other formats are
    # supported, will simply return nil if format is not
    # book or journal.
    def openurl_genre
      if (openurl_format == "journal" &&
          ["a", "t"].include?(marc.leader.slice(6,1))
         )
          #language material or manuscript language material
          return "journal"
      elsif (openurl_format == "book" &&
             ["a", "t"].include?(marc.leader.slice(6,1))
            )
          return "book"
      elsif (["journal", "book"].include? openurl_format  )
        # it's not language material? Forget it, we're calling it:
        return "unknown"
      else
        # it's not book or journal format at all? genre does not apply.
        return nil
      end
    end

     def build_and_get_first_line(key, seperator = " ")
       first_line( build_presenter_from_key( key ) , seperator )
     end

     def build_presenter_from_key(key)
       MarcDisplay::FieldPresenter.new(nil, marc, mappings[key])
     end

     # Returns a single string value, or nil if none available.
     def first_line(presenter, seperator = " ")
       return nil if presenter.lines.length == 0

       return presenter.lines[0].join(seperator)
     end

   end
end
