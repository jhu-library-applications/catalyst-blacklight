# This class is used for processing the online access data
# before it is sent to the view. 
class OnlineAccessPresenter
    attr_reader :urls
  
  
    def initialize(urls:)
      @urls = urls
    end
  
    def overflow
      @urls = if @urls.size > 3
                { show_urls:  @urls.first(3),
                  overflow_urls:  @urls.last(urls.length - 3) }
              else
                { show_urls: @urls }
              end
      @urls
    end
  end
