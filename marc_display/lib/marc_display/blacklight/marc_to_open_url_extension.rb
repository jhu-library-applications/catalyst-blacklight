require 'marc_display/marc_to_open_url'

module MarcDisplay
  module Blacklight
    # A Blacklight document extension, to provide better OpenURL translation
    # from marc. Add it to your Blacklight solr model class AFTER you've
    # added your marc extension:
    # SolrMarc.use_extension(
    # MarcDisplay::Blacklight::MarcToOpenUrlExtension) do |document|
    #   document.respond_to?(:to_marc)
    # end
    #
    # If you'd like to have a URI pointing back to blacklight included as
    # a rfr_id, then include a :self_uri_prefix in the solr document's
    # extension_parameters. Eg:
    #   SolrDocument.extension_parameters[:self_uri_prefix] = "http://myhost.edu/catalog/"
    #  => Will add the document's ID on to the end of the prefix
    #
    # If you'd like a rfr_id to be set in the generated openurl, set
    # SolrDocument.extension_paramaters[:rfr_id] = "info:sid:something.com/something"
    module MarcToOpenUrlExtension

      def self.extended(document)
        document.will_export_as(:openurl_ctx_xml, "application/x-openurl-ctx+xml")
        document.will_export_as(:openurl_ctx_kev, "application/x-openurl-ctx-kev")
      end

      def to_openurl
        unless defined? @_ctx
          @_ctx = MarcDisplay::MarcToOpenUrl.new(to_marc).build_openurl

          if ( prefix = self.class.extension_parameters[:self_uri_prefix]  )
            @_ctx.referent.add_identifier( prefix +  self["id"] )
          end
          @_ctx.referrer.add_identifier( self.class.extension_parameters[:rfr_id] || "info:sid:projectblacklight.org" )
        end

        return @_ctx
      end

      # param needs to be there to be arrity compatible with one
      # we're over-riding, even though we do nothing with it.
      def export_as_openurl_ctx_kev(ignored_param = nil)
        unless defined? @_ctx_kev
          @_ctx_kev = to_openurl.kev
        end
        return @_ctx_kev
      end


      def export_as_openurl_ctx_xml
        unless defined? @_ctx_xml
          @_ctx_xml = to_openurl.xml
        end
        return @_ctx_xml
      end

    end
  end
end
