# frozen_string_literal: true
class Project < ApplicationRecord
  belongs_to :created_by_user, class_name: "User"

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

  def in_mediaflux?
    mediaflux_id.present?
  end

  def self.sponsored_projects(sponsor)
    Project.where("metadata_json->>'data_sponsor' = ?", sponsor)
  end

  def approve!(session_id:, created_by: netid)
    asset_id = ProjectMediaflux.create!(project: self, session_id: session_id, created_by: created_by)
    if asset_id.present?
      Rails.logger.debug "Project #{id} has been saved to MediaFlux (asset id #{asset_id.to_i})"
      self.mediaflux_id = asset_id.to_i
      save!
    else
      raise "Error saving project to mediaflux"
    end
  end

  def update_mediaflux(session_id:, updated_by:)
    ProjectMediaflux.update(project: self, session_id: session_id, updated_by: updated_by)
    Rails.logger.debug "Project #{id} has been updated in MediaFlux (asset id #{mediaflux_id}"
  end
end
