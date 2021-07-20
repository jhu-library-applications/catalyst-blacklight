
# Cheesy Rails2 engines method of adding methods to CatalogController, hope
# it works.

#require 'blacklight/catalog'
require 'unstem_solr_params'
require 'home_page_solr_params_logic'
require 'ils_status'

# Not sure why we need to explicitly require our SearchBuilder
# class, but BL isn't finding it if we don't. BL 5.14.
require 'search_builder'

require 'dlf_expanded_passthrough/document_extension'

class CatalogController < ApplicationController
  include CqlHelper

  # @TODO: BL should do this, but it is not working here
  # Recreating locally to ensure layout choice is correct
  layout :determine_layout

  # Required by Find It / Umlaut
  include BlacklightCql::ControllerExtension

  def index
    super

    if params[:content_format] == 'marc' && params[:search_field] == 'cql' && params[:format] == 'html'
      redirect_to search_catalog_url reformatted_cql_search(params: params)
    end
  end

  # @TODO: Strong params everywhere
  ActionController::Parameters.permit_all_parameters = true

  PERMIT_PARAMS = [
      :range_end,
      :range_field,
      :range_start,
      :id,
      :amp,
      :op,
      :suppress_spellcheck,
      :page,
      :results_view,
      :subject_topic_facet,
      :bento_redirect,
      :format,
      :q,
      :unstemmed_search,
      :utf8,
      :all_fields,
      :title,
      :author,
      :subject,
      :number,
      :publisher,
      :series,
      :call_number,
      :commit,
      :sort,
      :per_page,
      :search_field,
      :only_path,
      :range => {
        :pub_date_sort => [
          :begin,
          :end
        ]
      },
      :f => {
        :format => [],
        :location_facet => [],
        :language_facet => [],
        :instrumentation_facet => [],
        :subject_topic_facet => [],
        :series_facet => []
      },
      :f_inclusive => {
        :format => [],
        :location_facet => [],
        :language_facet => [],
        :instrumentation_facet => []
      }
    ]

  include BlacklightAdvancedSearch::Controller
  include Blacklight::Catalog
  include BlacklightUnapi::ControllerExtension

  include BlacklightRangeLimit::ControllerOverride

  include Blacklight::Marc::Catalog
  include DlfExpandedPassthrough::BulkLoad

  before_action :require_login, :only => [:sms_form, :sms_send, :email]

  before_action :redirect_legacy_values, :only => :index
  before_action :redirect_legacy_advanced_search, :only => :index
  before_action :remove_unused_facet_limits, :only => [:index, :facet]
  before_action :avoid_nonexisting_facet_drilldown, :only => :facet
  # before_action :remove_bad_range_param, :only => [:index, :facet]
  before_action :json_cors_headers
  before_action :x_frame_headers

  configure_blacklight do |config|

    # Do not store searches for bots
    config.crawler_detector = ->(req) { req.env['HTTP_USER_AGENT'] =~ /bot/ }

    # default components
    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)

    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'edismax'
    config.advanced_search[:form_solr_parameters] ||= {
      "facet.field" => ["access_facet", "format", "location_facet", "language_facet", "instrumentation_facet"],
      "facet.limit" => -1, # return all facet values
      "facet.sort" => "index" # sort by byte order of values
    }
    config.advanced_search[:advanced_parse_q] ||= true
    config.advanced_search[:form_facet_partial] ||= "advanced_search_facets_as_select"

    # Tell ruby marc to use best available installed parser, hopefully
    # nokogiri.
    MARC::XMLReader.best_available!

    config.search_builder_class = ::SearchBuilder

    config.default_solr_params = {
    :qt => "search",
    :rows => 10,
    :mm => "100%", # in 'all fields' def, over-ride to less than 100%
    :"facet.limit" => 9,
    :"f.format.facet.limit" => -1,
    :"facet.field" => [
      "format",
      "access_facet",
      "location_facet",
      "author_facet",
      "organization_facet",
      "language_facet",
      "series_facet",
      #"discipline_facet",
      "subject_topic_facet",
      "subject_geo_facet",
      "subject_era_facet",
      "instrumentation_facet"
      ]
    }

    # Field list for fetching multiple documents by id
    config.fetch_many_document_params = {
      fl: "*"
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    #config.default_document_solr_params = {
    #  :qt => 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #  # :fl => '*',
    #  # :rows => 1
    #  # :q => '{!raw f=id v=$id}'
    #}

    # solr field configuration for search results/index views
    config.index.title_field = 'title_display'
    config.index.display_type_field = 'format'

    # solr field configuration for document/show views
    config.show.title_field = 'title_display'
    config.show.display_type_field = 'format'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    config.add_facet_field  "access_facet",   :label => "Access", :limit => 2, :collapse => false
    config.add_facet_field  "format",         :label => "Format", :limit => false # no limit as we show all format values
    config.add_facet_field  "location_facet", :label => "Item Location", :limit => true
    config.add_facet_field  "pub_date_sort",  :label => "Publication Year", :range => true
    config.add_facet_field  "author_facet",   :label => "Author", :limit => true
    config.add_facet_field  "organization_facet",   :label => "Organization", :limit => true
    config.add_facet_field  "language_facet", :label => "Language", :limit => true
    config.add_facet_field  "subject_topic_facet", :label => "Subject", :limit => true
    config.add_facet_field  "subject_geo_facet",   :label => "Region", :limit => true
    config.add_facet_field  "subject_era_facet",   :label => "Era", :limit => true
    config.add_facet_field  "series_facet",        :label => "Series", :limit => true
    #config.add_facet_field  "discipline_facet",    :label => "Discipline", :limit => true
    config.add_facet_field  "instrumentation_facet", :label => "Musical Instrumentation", :limit => true

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'title_display', :label => 'Title:'
    config.add_index_field 'title_vern_display', :label => 'Title:'
    config.add_index_field 'author_display', :label => 'Author:'
    config.add_index_field 'author_vern_display', :label => 'Author:'
    config.add_index_field 'format', :label => 'Format:'
    config.add_index_field 'language_facet', :label => 'Language:'
    config.add_index_field 'published_display', :label => 'Published:'
    config.add_index_field 'published_vern_display', :label => 'Published:'
    config.add_index_field 'lc_callnum_display', :label => 'Call number:'
    config.add_index_field 'isbn', :label => 'ISBN:'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'title_display', :label => 'Title:'
    config.add_show_field 'title_vern_display', :label => 'Title:'
    config.add_show_field 'subtitle_display', :label => 'Subtitle:'
    config.add_show_field 'subtitle_vern_display', :label => 'Subtitle:'
    config.add_show_field 'author_display', :label => 'Author:'
    config.add_show_field 'author_vern_display', :label => 'Author:'
    config.add_show_field 'format', :label => 'Format:'
    config.add_show_field 'url_fulltext_display', :label => 'URL:'
    config.add_show_field 'url_suppl_display', :label => 'More Information:'
    config.add_show_field 'language_facet', :label => 'Language:'
    config.add_show_field 'published_display', :label => 'Published:'
    config.add_show_field 'published_vern_display', :label => 'Published:'
    config.add_show_field 'lc_callnum_display', :label => 'Call number:'
    config.add_show_field 'isbn_t', :label => 'ISBN:'


    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    config.add_search_field "all_fields" do |field|
      field.label = "Any Field"
      field.solr_parameters = {
        :mm => "3<-1 6<80%"
      }
    end

    config.add_search_field("title") do |field|
      field.label = 'Title'
      field.solr_local_parameters = {
        :qf => "$title_qf",
        :pf => "$title_pf"
      }
      field.solr_parameters = {
        :"spellcheck.dictionary" => "title"
      }
    end

    config.add_search_field("author") do |field|
      field.label = 'Author'
      field.solr_local_parameters = {
        :qf => "$author_qf",
        :pf => "$author_pf"
      }
      field.solr_parameters = {
        :"spellcheck.dictionary" => "author"
      }
    end

    config.add_search_field("subject") do |field|
      field.label = 'Subject'
      field.solr_local_parameters = {
        :qf => "$subject_qf",
        :pf => "$subject_pf"
      }
      field.solr_parameters = {
        :"spellcheck.dictionary" => "subject"
      }
    end

    # Combining numbers is weird. Call numbers end up as multiple tokens,
    # so we use pf/ps/mm to try to make sure call number searches are reasonable
    # Everything else should just be one token, usually.
    config.add_search_field("number") do |field|
      field.label = "Numbers"
      field.solr_local_parameters = {
        :qf => "$numbers_qf",
        :pf => "$numbers_pf"
      }
      field.solr_parameters = {
        :mm=>"100%",
        :ps => "0",
        :spellcheck => "false"
      }
    end

    # Journal title is a copy of title -- we have custom logic below
    # that hardcodes in the facet limit.
    config.add_search_field("journal_title") do |field|
      field.label = 'Journal Title'
      field.solr_local_parameters = {
        :qf => "$title_qf",
        :pf => "$title_pf" ,
      }
      field.solr_parameters = {
        :"spellcheck.dictionary" => "title"
      }
      # Making this work right in advanced search is harder,
      # make it not show up for now, which isn't perfect, but okay.
      field.include_in_advanced_search = false
    end

    config.add_search_field("publisher") do |field|
      field.label = "Publisher"
      field.qt = "search"
      field.include_in_simple_select = false
      field.solr_parameters = {
        :qf => "publisher_t",
        :pf => "publisher_t^10"
      }
    end



    config.add_search_field("series") do |field|
      field.label = 'Series Title'
      field.qt = 'search'
      field.include_in_simple_select = false
      field.solr_local_parameters = {
        :qf => "$series_qf",
        :pf => "$series_pf"
      }
    end

    ####
    # Hidden searches.
    # We don't want ISBN/ISSN/Callnum/Oclcnum/LCCN in our search popup
    # But we leave them defined here for CQL access, but with
    # :show_in_simple_select => false

    config.add_search_field("isbn") do |field|
      field.label = "ISBN"
      field.qt = "search"
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :qf => "isbn_t",
        :pf =>"",
        :spellcheck => "false"
      }
    end


    config.add_search_field("issn") do |field|
      field.label = 'ISSN'
      field.qt = 'search'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :qf => "issn issn_related",
        :pf => "",
        :spellcheck => "false"
      }
    end

    config.add_search_field("oclcnum") do |field|
      field.label = 'OCLC number'
      field.qt = 'search'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :qf => "oclcnum_t",
        :pf => "",
        :spellcheck => "false"
      }
    end

    config.add_search_field("call_number") do |field|
      field.label = 'Call number'
      field.qt  = "search"
      field.include_in_simple_select = false
      field.solr_parameters = {
        :qf => "local_call_number_t",
        :mm=>"100%",
        :pf =>"local_call_number_t^100",
        :ps => "0",
        :spellcheck => "false"
      }
    end

    config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance', :default => true
    config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year'
    config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
    config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Add documents to the list of object formats that are supported for all objects.
    # This parameter is a hash, identical to the Blacklight::Solr::Document#export_formats 
    # output; keys are format short-names that can be exported. Hash includes:
    #    :content-type => mime-content-type
      
    config.unapi = {
      'oai_dc_xml' => { :content_type => 'text/xml' } 
    }
    config.index.partials << 'microformat'
    config.show.partials << 'microformat'



    # Used by our custom UnstemSolrParams module
    # These are over-rides sent to Solr when in :unstemmed_search mode
    # They need to be kind of carefully calibrated with the settings in Solr
    # and Blacklight for individual search types, sorry it's a bit fragile.
    config.unstemmed_overrides = {
      :title_qf => [
        "title_unstem^80",
        "title1_unstem^60",
        "title2_unstem^40",
        "title3_unstem^30",
        "title_series_unstem^25"
      ],

      :subject_qf  => "subject_unstem^40",
      :series_qf   => "title_series_unstem^10",
      # this 'qf' will be used for default 'all fields' search
      # when in unstemmed mode, over-riding the qf defaults set
      # in solrconfig.xml, which include some stemmed fields.
      :qf => [
        'title_unstem^80',
        'title2_unstem^60',
        'title3_unstem^20',
        'author_unstem^90',
        'author_addl_unstem^40',
        'subject_unstem^20',
        'title_series_unstem^10',
        'isbn_t',
        'issn',
        'issn_related',
        'local_call_number_t',
        'oclcnum_t',
        'lccn',
        'instrumentation_code_unstem',
        'text_unstem^2',
        'text_extra_boost_unstem^6'
      ]
    }

    # We want to disable the standard BL "send an SMS" function from document
    # show page. Because we use custom item/copy-specific SMS functions instead.
    # This seems to be the recommended way to do that:
    config.show.document_actions[:sms].if = false if config.show.document_actions[:sms]
    config.show.document_actions[:refworks].partial = 'refworks'

    # We want to try and re-order the show.document_actions to our desired order.
    # This appears to be one way to do it, deleting and reinserting everything we want.
    # https://github.com/projectblacklight/blacklight/issues/1182
    desired_order = [:bookmark, :citation, :refworks, :endnote, :email, :librarian_view]
    # Make sure we have any other existing keys on the end of our desired order list too
    desired_order.concat(  config.show.document_actions.keys - desired_order  )
    # Now delete and re-insert each one
    desired_order.each do |key|
      value = config.show.document_actions.delete(key)
      config.show.document_actions[key] = value if value
    end
  end

  # Handles errors when bib#'s have been removed by returning a 404 page
  rescue_from Blacklight::Exceptions::RecordNotFound, :with => -> { render status: 404, layout: 'blacklight', template: 'errors/not_found.html.erb' }

  # Handles errors that are caused by Find It using blacklight-cql. If the user or system makes a CQL
  # syntax error we don't want to raise an exception.
  rescue_from CqlRuby::CqlException, :with => -> { render status: 404, layout: 'blacklight', template: 'errors/not_found.html.erb' }

  # Solr search manipulation, method mentioned here, but actually
  # defined in SearchBuilder -- we are also adding them to
  # SearchBuilder.default_processor_chain for future-proofing,
  # so we'll just make sure the logic here reflects that.
  #
  # Anything already mentioned in SearchBuilder.default_processor_chain
  # but not yet here, add here.
  #
  #self.search_params_logic += (SearchBuilder.default_processor_chain - self.search_params_logic)


  def copy
    @response, @document = search_service.fetch(params[:id])
    @item_holdings = @document.to_holdings_for_holdingset(params[:copy_id])

    if @item_holdings.nil?
      render(:status => 404, :text => "Horizon copy not found: #{ActionController::Base.helpers.sanitize params[:copy_id]}") and return
    end

    respond_to do |format|
      format.html { }
      format.dlf_expanded { render :text =>  @document.to_dlf_expanded_for_holdingset(params[:copy_id]) }
      format.xml { render :text =>  @document.to_dlf_expanded_for_holdingset(params[:copy_id]) }

    end
  end

  # custom action to send SMS for a particular item in a particular bib.
  # requires an :id (solr unique id) _and_ a :holding_id . The :holding_id
  # somewhat evil-ly can be either an item or copy ID -- it's just an id that
  # should match some item in @document.to_holdings .
  # GET for form
  def sms_form
    # just default render of appropriate view
  end


  #POST for sending
  def sms_send
    @response, @document = search_service.fetch(params[:id])
    if @document.blank?
      flash[:error] = "Sorry, record not found."
      redirect_to_params params[:referer] || solr_document_path(params[:id])
      return
    end

    @holding = @document.to_holdings.find {|h| h.id == params[:holding_id] }

    email_from = request.host
    url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}

    phone_num = params[:to].gsub(/[^\d]/, '') if params[:to]

    @error_message = "Sorry, record not found." if @holding.nil?
    @error_message = "Please select a carrier."     if params[:carrier].blank?
    @error_message = "Please enter a 10-digit phone number" if phone_num.blank?

    if @error_message
      render "sms_form"
    else
      JhSmsSend.sms_record(@document, @holding, {:to => phone_num, :carrier => params[:carrier], :email_from_host => email_from, :url_gen_params => url_gen_params}).deliver_now
      @success_message = "Text message sent to #{params[:to]}"
      if request.xhr?
        # AJAX modal, render the sms_form, which will trigger JS to close
        render "sms_form"
      else
        referer = sanitize_redirect_url
        redirect_to referer, :flash => {:success => @success_message}
      end
    end
  end

  # rails_stackview-powered shelf browse
  def shelfbrowse
    render :template => 'rails_stackview/browser', :locals => {:origin_sort_key => params["origin_sort_key"] || "M"}
  end

  # Returns partial HTML loaded by the rails_stackview AJAX on browse clicks.
  def shelfbrowse_item
    cat = Blacklight::SearchService.new(
      config: CatalogController.blacklight_config
    )

    _, doc = cat.fetch(params[:id])

    render :partial => "shelfbrowse_item", :locals => {:document => doc, :call_number => params[:sort_key_display]}
  end

  protected

  # Determine Layout
  def determine_layout
    return false if request.xhr?
    action_name == 'show' ? 'catalog_result' : super
  end

   # Blacklight will use this to determine how many values
  # to show at once on the individual facet page.
  def facet_list_limit
    20
  end


  # Over-ride some facet link helper methods, so we add suppress_spellcheck=1
  # on facet add/remove
  helper Module.new do
    def add_facet_params(*args)
      results = super
      results[:suppress_spellcheck] = "1"
      return results
    end

    def remove_facet_params(*args)
      results = super
      results[:suppress_spellcheck] = "1"
      return results
    end

  end

  def redirect_legacy_values
    should_redirect = false

    # Check for things we want to change; we mutate params in place,
    # cause it shouldn't matter since we're only going to redirect
    # and stop further processing.

    if params[:f] && params[:f][:format] && (index = params[:f][:format].index("Serial"))
      params[:f][:format][index] = "Journal/Newspaper"

      should_redirect = true
    end

    # Check for old format style of params[:f][:format] = [[Book], [Online]] and converts it to params[:f][:format] = [Book, Online]
    if (params[:bento_redirect] == 'true') && params[:f] && params[:f][:format] && (params[:f][:format].kind_of? Array)
      if params[:f][:format][0].kind_of? Array
        params[:f][:format] = params[:f][:format].map{ |f| f[0] }
        should_redirect = true
      end
    end

    redirect_to url_for(params.merge(:only_path => true).permit(PERMIT_PARAMS)), :status => :moved_permanently if should_redirect
  end

  def redirect_legacy_advanced_search
    if params[:f_inclusive] && params[:f_inclusive].respond_to?(:each_pair)
      legacy_converted = false

      params[:f_inclusive].each_pair do |field, value|
        if value.kind_of? Hash
          # old style! convert!
          legacy_converted = true
          params[:f_inclusive][field] = value.keys
        end
        # added after upgrade to BL v7 tp convert f_include[format][Book] = 1 to f_include[format][] = Book
        if value.respond_to?(:keys)
          if value.keys.kind_of? Array
            # old style! convert!
            legacy_converted = true
            params[:f_inclusive][field] = [value.keys.first]
          end
        end
      end

      if legacy_converted
        # Safe way to redirect to modification of existing params
        # https://github.com/rails/rails/pull/16170
        redirect_to url_for(params.merge(:only_path => true).permit(PERMIT_PARAMS)), :status => :moved_permanently

      end
    end
  end

  # if someone requests a facet limit for a facet that doens't exist (but maybe used to),
  # current Blacklight (5.6.0) will raise a fatal unexpected error, and/or
  # include the facet limit in the Solr request anyway resulting in 0 hits.
  # We want to remove the unused facet, and then redirect without it, so an unused
  # facet is basically a no-op.
begin
  def remove_unused_facet_limits
    bad_facets = (params[:f].try(:keys) || []).find_all do |limited_facet|
      ! blacklight_config.facet_fields.keys.include? limited_facet
    end
    if bad_facets.length > 0
      # they requested one or more facet limits that aren't configured, redirect
      # without those.
      f = params[:f].except(*bad_facets)
      redirect_to url_for(params.merge(:f => f).permit(PERMIT_PARAMS)), :status => :moved_permanently
    end
  end
end

  # on request for facet/something, where 'something' is not a valid facet,
  # just return a 404 -- in Blacklight 5.6.0, otherwise we get a fatal unexpected
  # exception, cluttering up our error logs.
begin
  def avoid_nonexisting_facet_drilldown
    facet = params[:id]
    unless blacklight_config.facet_fields.keys.include? facet
      render :status => 404, :text => "No such facet: #{ActionController::Base.helpers.sanitize facet}"
    end
  end
end

  # @TODO - Removing EWL
  # Googlebot is sending queries with empty or string 'range' params,
  #     &range=&x or &range=foo
  # A range param that isn't a Hash messes up blacklight_range_limit
  # Not sure how to fix it in blacklight_range_limit, easiest thing
  # is to guard it here, and redirect removing range param
  # def remove_bad_range_param
  #   if params.has_key?(:range) && !params[:range].kind_of?(Hash)
  #    redirect_to_params params.except(:range)
  #  end
  # end

  # Add CSP header to allow i-frame
  def x_frame_headers
      response.headers["X-Frame-Options"] = "ALLOW-FROM https://jhu.libwizard.com/"
  end

  # Add CORS headers for JSON API responses
  def json_cors_headers
    if params[:format] == "json" || request.format == "application/json"
      response.headers["Access-Control-Allow-Origin"] = "*"
    end
  end

  # @TODO: EWL
  # Ordinary `redirect_to params` is unsafe and Rails will refuse
  # to do it at present. This seems like a safe way, and is a way
  # Rails will do.
  # https://github.com/rails/rails/pull/16170
  # def redirect_to_params(params)
  #  redirect_to url_for(params) # TEST
    # redirect_to url_for(params.merge(:only_path => true).permit(:only_path => true))
  # end

  # makes sure user is logged in, and inits a hip pilot object if so
  def require_login
    unless current_user
      if request.xhr?
        # ajaxy request, redirecting to login isn't going to work right,
        # give em a 403 telling em we can't do it. Body contains a data-force-login,
        # that our JS code will catch and redirect to authentication, and a data-request-url
        # that our JS code will use to... do overly complex hacky stuff so when they are done
        # logging in, they get the request modal again.

        if action_name == 'email'
          message = 'Please log in to send a record by email.'
        elsif action_name == 'sms_form' or action_name == 'sms_send'
          message = 'To send a record by text, please log in and provide the cell number and carrier name.'
        else
          message = 'Please log in to continue' # this shouldn't happen
          logger.warn "Require login by something other than email and sms: #{action_name}"
        end
        flash[:notice] = message

        body = "<span data-force-login='#{new_user_session_url}' data-request-path='#{request.path}'>Request requires authentication, which can't be done over an xhr request.</span>"

        render html: body.html_safe
      else
        # raise the exception that will cause redirect to login screen.
        flash[:notice] = "Please log in." and raise Blacklight::Exceptions::AccessDenied
      end
    end
  end

end
