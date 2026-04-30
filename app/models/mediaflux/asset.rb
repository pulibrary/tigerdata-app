# frozen_string_literal: true
module Mediaflux
  class Asset
    attr_accessor :id, :path, :collection, :size, :collection_count, :file_count, :folder_size

    attr_accessor :id, :type, :path, :size, :collection

    # Returns the collection type string used by Mediaflux to identify collections.
    # @return [String] the collection type string used by Mediaflux to identify collections
    def self.collection_type
      "application/arc-asset-collection"
    end

    # Constructor
    # @param id [String] the unique identifier for the asset
    # @param name [String] the name of the asset
    # @param type [String] the type of the asset (e.g., "application
    #   /arc-asset-collection" for collections or "application/octet-stream" for files)
    # @param collection [String] the collection to which the asset belongs
    # @param path [String, nil] the path to the asset in Mediaflux (
    #   e.g., "/tigerdata/projectg/folder1/file-abc.txt")
    # @param created_at_mf [String, nil] the created date of the asset in the format
    #   used by Mediaflux (e.g., "07-Feb-2024 21:48:01")
    # @param last_modified_mf [String, nil] the last modified date of the asset in the
    #   format used by Mediaflux (e.g., "07-Feb-2024 21:48:01")
    # @param size [Integer, nil] the size of the asset in bytes
    # @param collection_count [Integer, nil] the number of collections contained within the asset (if it's a collection)
    # @param file_count [Integer, nil] the number of files contained within the asset (if it's a collection)
    # @param folder_size [Integer, nil] the total size of all files contained within the asset (if it's a collection)
    # @return [Mediaflux::Asset] a new instance of Mediaflux::Asset with the provided attributes
    def initialize(id:, name:, type:, collection:, path: nil, created_at_mf: nil, last_modified_mf: nil, size: nil, collection_count: nil, file_count: nil, folder_size: nil)
      @id = id
      @name = name
      @type = type
      @collection = collection

      @path = path
      @created_at_mf = created_at_mf
      @last_modified_mf = last_modified_mf
      @collection_count = collection_count
      @file_count = file_count
      @folder_size = folder_size

      @size = size
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

    # Returns true if the asset is a collection, false otherwise
    # @return [Boolean] true if the asset is a collection, false otherwise
    def collection?
      collection || type == self.class.collection_type
    end

    # Returns the size of the asset in a human-readable format (e.g., "2.5 MB" or "500 KB").
    # @return [String, nil] the size of the asset in a human-readable format or nil if the size is not available
    def human_size
      return nil if size.nil?

      ActiveSupport::NumberHelper.number_to_human_size(size)
    end

    # Returns the path to the asset but without the root collection namespace as part of it.
    #
    # Example:
    #   path        -> "/tigerdata/projectg/folder1/file-abc.txt"
    #   path_short  -> "/projectg/folder1/file-abc.txt"
    def path_short
      return nil if path.nil?
      if path.starts_with?(Mediaflux::Connection.root_collection_namespace)
        path[Mediaflux::Connection.root_collection_namespace.length..-1]
      else
        path
      end
    end

    # Returns the last modified date but using the standard ISO 8601 (https://en.wikipedia.org/wiki/ISO_8601)
    # @return [String, nil] the last modified date in ISO 8601 format or nil if the last modified date is not available
    def last_modified
      return nil if @last_modified_mf.nil?
      # https://nandovieira.com/working-with-dates-on-ruby-on-rails
      # Mediaflux dates are in UTC and look like this "07-Feb-2024 21:48:01"
      Object::Time.zone.parse(@last_modified_mf).in_time_zone("America/New_York").iso8601
    end

    # Returns the created date but using the standard ISO 8601 (https://en.wikipedia.org/wiki/ISO_8601)
    # @return [String, nil] the created date in ISO 8601 format or nil if the created date is not available
    def created_at
      return nil if @created_at_mf.nil?
      default_local_time_zone = "America/New_York"

      # Mediaflux dates are in UTC and look like this "07-Feb-2024 21:48:01"
      utc_value = Object::Time.zone.parse(@created_at_mf)
      eastern_time_value = utc_value.in_time_zone(default_local_time_zone)
      eastern_time_value.iso8601
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
      if collection?
        path_short
      else
        p = Pathname.new(path_short)
        p.dirname.to_s
      end
    end

    def as_json(options = {})
      super(options).merge({
                             id: id,
                             name: name,
                             path: path,
                             collection: collection,
                             size: size,
                             last_modified: last_modified,
                             last_modified_mf: @last_modified_mf,
                             asset_count: asset_count,
                             folder_size: folder_size
                           })
    end

    def asset_count
      collection_count + file_count
    end
  end
end
