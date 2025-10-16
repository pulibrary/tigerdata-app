# frozen_string_literal: true
module Mediaflux
  class Connection
    # The host nome for the Mediaflux server
    # @return [String]
    def self.host
      Rails.configuration.mediaflux["api_host"]
    end

    # The host port for the Mediaflux server
    # @return [Integer]
    def self.port
      Rails.configuration.mediaflux["api_port"].to_i
    end

    # The host transport for the Mediaflux server
    # @return [String]
    def self.transport
      Rails.configuration.mediaflux["api_transport"]
    end

    def self.root
      Rails.configuration.mediaflux["api_root"]
    end

    def self.root_collection
      Rails.configuration.mediaflux["api_root_collection"]
    end

    def self.root_collection_namespace
      Rails.configuration.mediaflux["api_root_collection_namespace"]
    end

    def self.root_collection_name
      Rails.configuration.mediaflux["api_root_collection_name"]
    end

    def self.root_namespace
      Rails.configuration.mediaflux["api_root_ns"]
    end

    def self.hidden_root
      Rails.configuration.mediaflux["api_hidden_root"]
    end
  end
end
