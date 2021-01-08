=begin
#require 'formatted_rails_logger'




# Over-ride method to make partial rendered lines only at DEBUG level,
# there are so many of them in the logs, ugh.
# http://stackoverflow.com/questions/12984984/how-to-prevent-rails-from-action-view-logging-in-production
module ActionView
    class LogSubscriber
       def render_template(event)
            message = "Rendered #{from_rails_root(event.payload[:identifier])}"
            message << " within #{from_rails_root(event.payload[:layout])}" if event.payload[:layout]
            message << (" (%.1fms)" % event.duration)
            debug(message)
       end
          alias :render_partial :render_template
          alias :render_collection :render_template
     end
  end
=end
