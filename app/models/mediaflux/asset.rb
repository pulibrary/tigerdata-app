# frozen_string_literal: true
module Mediaflux
  class Asset
    attr_accessor :id, :path, :collection, :size

    def initialize(id:, name:, collection:, path: nil, last_modified_mf: nil, size: nil)
      @id = id
      @name = name
      @path = path
      @collection = collection
      @size = size
      @last_modified_mf = last_modified_mf
    end

    def name
      # Mediaflux supports the concept of files without a name and in those cases the
      # "name" property might be empty, but the actual name assigned internally by
      # Mediaflux (e.g. __asset_id__4665) is still reflected in the path.
      if @name == ""
        Pathname.new(path).basename.to_s
      else
        @name
      end
    end

    # Returns the path to the asset but without the root namespace as part of it.
    #
    # Example:
    #   path        -> "/tigerdata/projectg/folder1/file-abc.txt"
    #   path_short  -> "/projectg/folder1/file-abc.txt"
    def path_short
      return nil if path.nil?
      if path.starts_with?(Rails.configuration.mediaflux["api_root_ns"])
        path[Rails.configuration.mediaflux["api_root_ns"].length..-1]
      else
        path
      end
    end

    # Returns the last modified data but using the standard ISO 8601 (https://en.wikipedia.org/wiki/ISO_8601)
    def last_modified
      return nil if @last_modified_mf.nil?
      # https://nandovieira.com/working-with-dates-on-ruby-on-rails
      # https://api.rubyonrails.org/classes/ActiveSupport/TimeWithZone.html
      # https://apidock.com/ruby/DateTime/strftime
      # Mediaflux dates are in UTC and look like this "07-Feb-2024 21:48:01"
      Time.zone.parse(@last_modified_mf).in_time_zone("EST").strftime("%Y-%m-%dT%H:%M:%S%:z")
    end

    # Returns the path for the asset
    # For a collection returns the path_short, but for a file is the dirname of the path_short
    #
    # Example for a file:
    #   path        -> "/tigerdata/projectg/folder1/file-abc.txt"
    #   path_short  -> "/projectg/folder1/file-abc.txt"
    #   path_only  -> "/projectg/folder1"
    # Example for a collection:
    #   path        -> "/tigerdata/projectg/folder1"
    #   path_short  -> "/projectg/folder1"
    #   path_only  -> "/projectg/folder1"
    def path_only
      return nil if path.nil?
      if collection
        path_short
      else
        p = Pathname.new(path_short)
        p.dirname.to_s
      end
    end
  end
end
