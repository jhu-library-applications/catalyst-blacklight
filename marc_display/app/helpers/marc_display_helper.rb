module MarcDisplayHelper

  # Default place to get our configs from.
  # call as marc_presenter_list(){} with an empty block get full expected fallthrough. 
  # first, local var passed in in render call: render(:partial => 'marc_display', :locals => {:marc_presenter_config = something })
  # Secondly, a local var that could be set in controller, @marc_presenter_config.
  # Third, the master default set in MarcDisplay::DefaultPresenterConfigList
  def marc_presenter_list(&context)
    return (context && eval("defined?(marc_presenter_list) && marc_presenter_list", context.binding)) || @marc_presenter_list || MarcDisplay::DefaultPresenterConfigList
  end
  
  # Give us a ruby marc field, get back any 880's that are linked. 
  def linked_marc_fields(marc_document, marc_field)
    #We've got this logic stored in MarcPresenter, expose it as a helper
    MarcDisplay::FieldPresenter.find_linked_fields(marc_document, marc_field)
  end

  # Used by marc_856 partial. Good thing to over-ride to for instance add in
  # ezproxy prefixes. 
  def link_out_to_856(value)
    value
  end
 
  # try to split a 505 contents field into individual entries. 
  def split_505_contents(marc505)
    # whether it's a 'formatted' note or not, really the only way to tell
    # where the entries are seperated is to split on '--'. Turns out
    # the formatting doesn't help much.

    # mash everything else together in the order it's presented.
    contents = marc505.find_all { |sf| ["a", "r","g","t"].include?(sf.code)  }.collect {|sf| sf.value }.join(" ")
        
    contents.split(" -- ")
  end

  # Used in 856 presenter
  def url_display_as(url)    
    begin
      return URI.parse(url).host
    rescue
      return url
    end    
  end  
  
end

