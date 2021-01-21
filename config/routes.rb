Catalyst::Application.routes.draw do

  get 'articles' => 'articles#index'
  
  # Error Pages for exception handling - EWL
  match '/404' => 'errors#not_found', via: :all
  match '/500' => 'errors#internal_server_error', via: :all

  if ActiveRecord::Base.connection.table_exists? 'flipper_features'
    ## Feature Flipper
    flipper_app = Flipper::UI.app(Flipper.instance) do |builder|
      builder.use Rack::Auth::Basic do |username, password|
        username == ENV['FLIPPER_USERNAME'] && password == ENV['FLIPPER_PASSWORD']
      end
    end
    mount flipper_app, at: '/flipper'
  end

  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  concern :marc_viewable, Blacklight::Marc::Routes::MarcViewable.new
  ####
  # Temporarily redirect 'catalog.library.jhu.edu' to 'catalyst.library.jhu.edu',
  # until we get shibboleth working for 'catalog' again.
  #constraints(:host => "catalog.library.jhu.edu") do
  #  get "*path" => redirect("https://catalyst.library.jhu.edu/%{path}")
  #end

  # blacklight_cql explain document
  get "catalog/explain" => "catalog#cql_explain"

  # Blacklight::Marc.add_routes(self)

  #Blacklight.add_routes(self)
  #
  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'


  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable

  end

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns [:exportable, :marc_viewable], :except => [:sms]
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # Blacklight provides a POST route for this, there is no GET path.
  # Some Bots are making lots o fGET requests and muddling up our logs,
  # let's explicitly route it to an error.
  get 'catalog/:id/track(.:format)', to: lambda {|ev| [405, {'Content-Type' => 'text/plain', 'Allow' => 'POST'}, ["Only POST method supported for this path"]]}


  # Apache does an OPTIONS /* request, just as a sort of ping.
  # let's keep it out of our 404 logs and just return a generic 200.
  # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
  match ':asterisk', via: [:options], constraints: { asterisk: /\*/ }, to:  lambda {|env| [200, {'Content-Type' => 'text/plain'}, ["OK\n"]]}


  # Custom routes. Add a 'shibboleth_login' path, pointing to
  # method in user_sessions
  get 'shibboleth_login' => 'user_sessions#shibboleth_create', :as => :shibboleth_login


  # For displaying copy information from horizon lookup for a designated copy
  get 'catalog/:id/copy/:copy_id(.:format)' => 'catalog#copy'

  # for filling out and submitting requests
  get 'catalog/:id/item/:item_id/request(.:format)' => 'requests#new', :as => :item_request
  post 'catalog/:id/item/:item_id/request(.:format)' => 'requests#create'


  # for our custom SMS sending with  holding, per holding
  get 'catalog/:id/sms/:holding_id' => 'catalog#sms_form'
  post 'catalog/:id/sms/:holding_id' => 'catalog#sms_send'

  # for our home-built auth. itemsout is considered main user
  # home page at the moment.
  get "user" => "users#itemsout", :as => "user"
  put "user/profile" => "users#update"
  get "login" => "user_sessions#index", :as => "new_user_session"
  get "logout" => "user_sessions#destroy", :as => "destroy_user_session"
  post "login" => "user_sessions#create", :as => "user_sessions"

  # for our account actions
  get 'user/itemsout' => redirect("/user") # /user/itemout used to be link, don't break it
  get 'user/requests' => "users#requests"
  get 'user/profile'  => "users#show"

  # reserves, mostly just ordinary resourceful, but with special
  # one for specifying location limit in path.
  # special location in path URL
  get 'reserves/location/:location' => 'reserves#index'
  resources :reserves

  # Redirecting old BentoSearch (multi_search) routes / EWL
  get '/disclaimer', to: redirect(path: '/articles', status: 301)

  get "/multi_search", to: redirect { |params, request|
    response_query = Rack::Utils.parse_query('bento_redirect=true')
    request_query  = Rack::Utils.parse_query(request.query_string)
    query          = request_query.merge(response_query)
    "/catalog?#{query.to_query}"
  }

  get "/search/articles", to: redirect { |params, request|
    response_query = Rack::Utils.parse_query('bento_redirect=true')
    request_query  = Rack::Utils.parse_query(request.query_string)
    query          = request_query.merge(response_query)
    "/articles?#{query.to_query}"
  }

  # Stackmap
  get 'floormap', :controller => "map", :action => "index"

  # rails_stackview powered shelf browse
  # actual shelfbrowse UI
  get 'shelfbrowse(/:call_type)', :to => "catalog#shelfbrowse", :as => "shelfbrowse"
  # Back-end controller returning json responses for stackview
  get 'stackview_data/:call_number_type', :to => "stackview_data#fetch", :as => "stackview_data"
  # Back-end returning html partial for clicks on items.
  get "shelfbrowse_item", :to => "catalog#shelfbrowse_item", :as => "stackview_browser_item"

  match '/:controller(/:action(/:id))', :via => [:get, :post]

  ##
  # Borrow Direct redirector
  get 'borrow_direct' => 'borrow_direct#index', :as => "borrow_direct"

  ###
  # Legacy Redirects
  ####

  get '/journals' => redirect("/search/articles")


  ###
  # Root
  ###


  # we do root statement LAST, so if a controller/action
  # has a root-path variant or it's own variant, it's OWN
  # variant is likely to be chosen, to keep our google analytics
  # more consistent. /catalog?q=foo, not /?q=foo.


  # We shouldn't generate any root-with-params URLs like /?foo=bar
  # anymore. But if one comes in from outside like that, REDIRECT
  # to /catalog?q=foo , for consistent analytics.  Change to multi_search
  # after we change.
  constraints(lambda {|req| req.query_parameters.present? }) do
    # need to use {} rather than do/end for precendence, argh.
    root :as => nil, :to => redirect { |params, request|
      "/multi_search?#{request.query_string}"
    }
  end

  # will change to multi_search#index when we make multi_search default.
  root :to => "catalog#index"
end
