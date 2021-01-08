module MarcDisplay
  
  class Engine < Rails::Engine
    # Mimic old vendored plugin behavior, marc_display/lib is autoloaded. 
    config.autoload_paths << File.expand_path("..", __FILE__)
    
    config.before_initialize do
      require 'marc_display/default_presenters'      
      MarcDisplay.extend MarcDisplay::DefaultPresenters
    end
  end

  

  
    


  

  
end
