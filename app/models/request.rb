# frozen_string_literal: true
class Request < ApplicationRecord
  def valid_to_submit?
    errors.clear
    valid_title? && valid_data_sponsor? && valid_data_manager? && valid_departments? && valid_quota? &&
      valid_description? && valid_parent_folder? && valid_project_folder? && valid_requested_by?
  end

  def valid_title?
    field_present?(project_title, :title)
  end

  def valid_data_sponsor?
    valid_uid?(data_sponsor, :data_sponsor)
  end

  def valid_data_manager?
    valid_uid?(data_manager, :data_manager)
  end

  def valid_departments?
    departments.present?
  end

  def valid_description?
    field_present?(description, :description)
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
end
