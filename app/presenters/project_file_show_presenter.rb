# frozen_string_literal: true
class ProjectFileShowPresenter
  include ActiveSupport::NumberHelper

  # Defines the attributes that will be delegated to the file object, allowing us to call these methods directly on the presenter
  delegate(:id, :name,
    :path, :path_only,
    :size, :collection?,
    :collection, :created_at,
    :created_by, :created_on,
    :last_modified, :asset_count, :folder_size, to: :file)

  # Provides read-only access to the file object, allowing us to access the file information through the presenter
  # @return [Mediaflux::Asset] the project file object containing the file information
  attr_reader :file

  # Initializes the presenter with a project file object
  # @param project_file [Mediaflux::Asset] the project file object containing the file information to be presented
  # @return [void]
  def initialize(project_file)
    @file = project_file
  end

  # Returns the default type string "unknown" to be used when the file type cannot be determined
  # @return [String] the default type string "unknown"
  def default_type
    "unknown"
  end

  # Returns the collection type string "collection" to be used when the file is identified as a collection
  # @return [String] the collection type string "collection"
  def collection_type
    "collection"
  end

  # Determines the type of the file based on whether it is a collection or by extracting the file extension from the name
  # @return [String] the type of the file (e.g., "collection", "jpg", "pdf", or "unknown")
  def type
    return collection_type if collection

    elements = name.split(".")
    return default_type if elements.empty?

    last = elements.last
    last.downcase
  end

  # Converts the file size to a human-readable format using ActiveSupport's number_to_human_size helper
  # @return [String] the file size in a human-readable format (e.g., "2.5 MB")
  def size_human
    number_to_human_size(size, precision: 2)
  end

  # Converts the folder size to a human-readable format using ActiveSupport's number_to_human_size helper
  # @return [String] the folder size in a human-readable format (e.g., "2.5 MB")
  def folder_size_human
    number_to_human_size(folder_size, precision: 2)
  end

  # Parses the last modified date and formats it as "MM/DD/YYYY"
  # @return [String] the formatted last modified date
  def last_modified_human
    parsed = Time.zone.parse(last_modified)
    parsed.strftime("%m/%d/%Y")
  end

  # Parses the created at date and formats it as "MM/DD/YYYY"
  # @return [String] the formatted created at date
  def created_on_human
    parsed = Time.zone.parse(created_at)
    parsed.strftime("%m/%d/%Y")
  end

  # Converts the file information to a hash format suitable for JSON serialization
  # @return [Hash] the file information as a hash
  def to_hash
    {
      id: id,
      name: name,
      path: path_only,
      size: size_human,
      type: type,
      created_by: created_by,
      created_on: created_on_human,
      last_modified: last_modified_human,
      asset_count: asset_count,
      folder_size: folder_size_human,
      collection: collection?
    }
  end

  # Overrides the default as_json method to include the file information in the JSON representation of the object
  # @param options [Hash] the options for JSON serialization
  # @return [Hash] the JSON representation of the object, including the file information
  def as_json(options = {})
    super(options).merge(to_hash)
  end
end
