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

  def directory
    metadata[:directory]
  end

  def self.sponsored_projects(sponsor)
    Project.where("metadata_json->>'data_sponsor' = ?", sponsor)
  end

  def approve!(session_id:, created_by: netid)
    asset_id = ProjectMediaflux.create!(project: self, session_id: session_id, created_by: created_by)
    if asset_id > 0
      Rails.logger.debug "Project #{self.id} has been saved to MediaFlux with id #{asset_id}"
      self.mediaflux_id = asset_id
      self.save!
    else
      raise "Error saving project to mediaflux"
    end
  end
end
