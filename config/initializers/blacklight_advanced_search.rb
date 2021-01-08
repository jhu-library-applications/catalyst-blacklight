if defined? BlacklightAdvancedSearch
  
  # Inject a filter into controller, to set the variable for single-column
  # layout.
  module AdvancedControllerOverrides
    def wide_right_sidebar_layout
      # Since we aren't setting this to a yui-* class, it won't get
      # a sidebar, sidebar will end up beneath, what we want. 
      @doc_classes = "wide_right_sidebar"
    end
      
  end
  
  Rails.application.config.to_prepare do
    unless AdvancedController.kind_of? AdvancedControllerOverrides
      #AdvancedController.send(:include, AdvancedControllerOverrides)
      #AdvancedController.before_filter(:wide_right_sidebar_layout, :only => :index)
      #AdvancedController.before_filter(:remove_advanced_javascript, :only => :index)
    end
  end


end
