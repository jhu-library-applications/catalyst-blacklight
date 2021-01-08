module ReservesHelper
  
  # sniff out http:// type URLs in a string, and turn em into hyperlinks
  def link_urls(string)
    # weird escaping but then embedding in new string that isn't html_safe
    # is neccesary to get around bug in rails 3.1: https://github.com/rails/rails/issues/1555
    string = String.new( html_escape(string)  ) 
    string.gsub(/(https?:\/\/[^ ]+)/) do |match|                        
      link_to($1, $1)
    end.html_safe
  end
  
end
