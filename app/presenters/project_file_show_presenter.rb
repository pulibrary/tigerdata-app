# frozen_string_literal: true

class ProjectFileShowPresenter
  include ActiveSupport::NumberHelper

  delegate :id, :name, :path, :size, :collection, :last_modified, :asset_count,
           :folder_size, :created_by, :created_on,
           to: :file
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

  def folder_size_human
    number_to_human_size(folder_size, precision: 2)
  end

  def to_hash
    {
      id: id,
      name: name,
      path: path,
      collection: collection,
      size: size_human,
      type: type,
      last_modified: last_modified.strftime("%m/%d/%Y"),
      created_by: created_by,
      created_on: created_on.strftime("%m/%d/%Y"),
      asset_count: asset_count,
      folder_size: folder_size_human
    }
  end

  # Object#as_json already calls to_hash and stringifies the keys.
  # Merging to_hash back in adds the same fields again under symbol keys,
  # and JSON.generate rejects that as a duplicate key.
end
