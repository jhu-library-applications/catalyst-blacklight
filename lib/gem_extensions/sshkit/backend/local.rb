module GemExtensions
  module SSHKit
    module Backend
      module Local
        def self.included(base)
          base.class_eval do
            define_method(:initialize) do |*args, &block|
              @host = ::SSHKit::Host.new(:local) # just for logging
              @block = block
              @host.properties[:server] = args.first
            end
          end
        end
      end
    end
  end
end
