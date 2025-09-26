# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
class Request < ApplicationRecord
  DRAFT = "draft" # default state set by database
  SUBMITTED = "submitted" # Ready to be approved

  def valid_to_submit?
    errors.clear
    # run all validations and then check for errors otherwise ruby stops at the first error
    valid_title?
    valid_data_sponsor?
    valid_data_manager?
    valid_departments?
    valid_quota?
    valid_project_purpose?
    valid_description?
    # Is parent folder really required?  For Skeletor let's skip it.
    # valid_parent_folder?
    valid_project_folder?
    # For Skeletor we are setting the requestor to the data sponsor
    # valid_requested_by?
    errors.count == 0
  end

  def valid_title?
    field_present?(project_title, :project_title)
    title_within_limit?(project_title, :project_title)
  end

  def valid_data_sponsor?
    valid_uid?(data_sponsor, :data_sponsor)
  end

  def valid_data_manager?
    valid_uid?(data_manager, :data_manager)
  end

  def valid_departments?
    field_present?(departments, :departments)
  end

  def valid_project_purpose?
    project_purpose_present?(project_purpose, :project_purpose)
  end

  def valid_description?
    field_present?(description, :description)
    description_within_limit?(description, :description)
  end

  def valid_parent_folder?
    field_present?(parent_folder, :parent_folder)
  end

  def valid_project_folder?
    field_present?(project_folder, :project_folder)
  end

  def valid_quota?
    if ((quota == "500 GB") || (quota == "2 TB") || (quota == "10 TB") || (quota == "25 TB")) ||
       (custom_quota? && (storage_size.present? && (storage_size > 0)) && ((storage_unit == "GB") || (storage_unit == "TB")))
      true
    else
      errors.add(:quota, :invalid, message: "must be one of '500 GB', '2 TB', '10 TB', '25 TB', or 'custom'")
      false
    end
  end

  def custom_quota?
    quota == "custom"
  end

  def valid_requested_by?
    field_present?(requested_by, :requested_by)
  end

  def approve(approver)
    create_project_operation = ProjectCreate.new
    result = create_project_operation.call(request: self, approver: approver)
    if result.success?
      result.value!
    else
      self.error_message = { message: result.failure }
      save!
      cleanup_incomplete_project
      raise ProjectCreate::ProjectCreateError, result.failure
    end
  end

  def approved_quota_size
    if approved_quota.present?
      if approved_quota == "custom"
        approved_storage_size.to_f
      else
        approved_quota.split.first.to_f
      end
    else
      requested_quota_size
    end
  end

  def requested_quota_size
    if custom_quota?
      storage_size.to_f
    else
      quota.split.first.to_f
    end
  end

  def approved_quota_unit
    if approved_quota.present?
      if approved_quota == "custom"
        approved_storage_unit
      else
        approved_quota.split.last
      end
    else
      requested_quota_unit
    end
  end

  def requested_quota_unit
    if custom_quota?
      storage_unit
    else
      quota.split.last
    end
  end

  def submitted?
    state == Request::SUBMITTED
  end

  private

    def field_present?(value, name)
      if value.present?
        true
      else
        errors.add(name, :invalid, message: "cannot be empty")
        false
      end
    end

    def valid_uid?(uid, field)
      if uid.blank?
        errors.add(field, :blank, message: "cannot be empty")
        false
      elsif User.where(uid: uid).count == 0
        errors.add(field, :invalid, message: "must be a valid user")
        false
      else
        true
      end
    end

    def project_purpose_present?(project_purpose, field)
      if project_purpose.blank?
        errors.add(field, :blank, message: "select a project purpose")
        false
      else
        true
      end
    end

    def description_within_limit?(description, field)
      if description.length > 1000
        errors.add(field, :invalid, message: "description cannot exceed 1000 characters")
        false
      else
        true
      end
    end

    def title_within_limit?(project_title, field)
      if project_title.length > 200
        errors.add(field, :invalid, message: "project title cannot exceed 200 characters")
        false
      else
        true
      end
    end

    # If a request fails to be a approved we make sure there were not orphan
    # project records left in our Rails database that do not have a matching
    # project in Mediaflux (i.e. collection asset).
    def cleanup_incomplete_project
      project = Project.find_by_id(project_id)
      if project && project.mediaflux_id.nil?
        Rails.logger.warn("Deleting project #{project.id} because the approval for request #{id} failed and it was not created in Mediaflux.")
        project.destroy!
      end
    end
end
# rubocop:enable Metrics/ClassLength
