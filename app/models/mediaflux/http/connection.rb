# frozen_string_literal: true
module Mediaflux
    module Http
      class Connection
        # The host nome for the Mediaflux server
        # @return [String]
        def self.host
            if Flipflop.alternate_mediaflux?  
                Rails.configuration.mediaflux["api_alternate_host"]
            else
              Rails.configuration.mediaflux["api_host"]
            end
        end
      end
    end
end
  