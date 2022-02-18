# This class is used for processing the online access data
# before it is sent to the view. 

# Targets are the URLs from SFX as an array of Nokogiri::XML::Element objects.
class OnlineAccessPresenter
    attr_reader :targets
  
    def initialize(targets:)
      @targets = targets.select { |t| t.css('target_name').text != "MESSAGE_NO_FULLTXT" }
    end
  
    def overflow
      @targets = if @targets.size > 3
                { show_targets:  @targets.to_a.first(3),
                  overflow_targets:  @targets.to_a.last(@targets.to_a.length - 3) }
              else
                { show_targets: @targets }
              end
      @targets
    end
  end
