# frozen_string_literal: true
class ProjectFileShowPresenter
  include ActiveSupport::NumberHelper

  delegate "id", "name", "path", "size", "collection", :last_modified, to: :file
  attr_reader :file

  def initialize(project_file)
    @file = project_file
  end

  def type
    return "collection" if collection

    if name.include?(".")
      name.split(".").last.downcase
    else
      "unknown"
    end
  end

  def size_human
    number_to_human_size(size, precision: 2)
  end

  def to_hash
    {
      id: id,
      name: name,
      path: path,
      collection: collection,
      size: size_human,
      type: type,
      last_modified: Time.zone.parse(last_modified).strftime("%m/%d/%Y")
    }
  end

  def as_json(options = {})
    super(options).merge(to_hash)
  end
end
