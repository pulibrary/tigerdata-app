# frozen_string_literal: true
class Project < ApplicationRecord
  def metadata
    (metadata_json || {}).with_indifferent_access
  end

  def metadata=(metadata)
    self.metadata_json = metadata
  end

  def title
    metadata[:title]
  end

  def departments
    metadata[:departments] || []
  end

  def self.sponsored_projects(sponsor)
    Project.where("metadata_json->>'data_sponsor' = ?", sponsor)
  end
end
