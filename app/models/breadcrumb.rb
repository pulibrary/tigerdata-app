# frozen_string_literal: true

# Represents a navigation breadcrumb with name and optional path.
class Breadcrumb
  attr_reader :name, :path

  # Initializes a new Breadcrumb instance.
  # @param name [String] The display name of the breadcrumb.
  # @param path [String, nil] The URL path for the breadcrumb link, can be nil.
  def initialize(name, path)
    @name = name
    @path = path
  end

  # Checks if the breadcrumb has a valid link path.
  # @return [Boolean] true if path is present, false otherwise.
  def link?
    @path.present?
  end
end
