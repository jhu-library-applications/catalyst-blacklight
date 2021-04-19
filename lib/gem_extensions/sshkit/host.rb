module GemExtensions
  module SSHKit
    module Host
      def self.included(base)
        base.class_eval do
          base.extend Forwardable
          base.def_delegators :'properties[:server]', :roles_array
        end
      end
    end
  end
end
