# frozen_string_literal: true
class Project < ApplicationRecord
  validates_with ProjectValidator

  def metadata
    (metadata_json || {}).with_indifferent_access
  end

  def metadata=(metadata)
    self.metadata_json = metadata
  end

  def title
    trailer = if in_mediaflux?
                ""
              else
                " (pending)"
              end
    metadata[:title] + trailer
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

  def self.managed_projects(manager)
    Project.where("metadata_json->>'data_manager' = ?", manager)
  end

  def self.data_user_projects(user)
    query = '{"data_user_read_only":["'+user+'"]}' #TODO: Find a better string solution, https://scalegrid.io/blog/using-jsonb-in-postgresql-how-to-effectively-store-index-json-data-in-postgresql/
    Project.where("metadata_json @> ? :: jsonb", query)
  end

  def approve!(session_id:, xml_namespace: nil)
    asset_id = ProjectMediaflux.create!(project: self, session_id: session_id, xml_namespace: xml_namespace)
    if asset_id.present?
      Rails.logger.debug "Project #{id} has been saved to MediaFlux (asset id #{asset_id.to_i})"
      self.mediaflux_id = asset_id.to_i
      save!
    else
      raise "Error saving project to mediaflux"
    end
  end

  def update_mediaflux(session_id:)
    ProjectMediaflux.update(project: self, session_id: session_id)
    Rails.logger.debug "Project #{id} has been updated in MediaFlux (asset id #{mediaflux_id}"
  end

  def created_by_user
    User.find_by(uid: metadata[:created_by])
  end
end
