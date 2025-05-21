# frozen_string_literal: true
class Request < ApplicationRecord
  def valid_to_submit?
    errors.clear
    valid_title? && valid_data_sponsor? && valid_data_manager? && valid_departments? && valid_quota? &&
      valid_description? && valid_parent_folder? && valid_project_folder? && valid_requested_by?
  end

  def valid_title?
    if project_title.blank?
      errors.add(:title, :blank, message: "cannot be empty")
    end
    project_title.present?
  end

  def valid_data_sponsor?
    data_sponsor.present?
  end

  def valid_data_manager?
    data_manager.present?
  end

  def valid_departments?
    departments.present?
  end

  def valid_description?
    description.present?
  end

  def valid_parent_folder?
    parent_folder.present?
  end

  def valid_project_folder?
    project_folder.present?
  end

  def valid_quota?
    quota.present? && quota > 0
  end

  def valid_requested_by?
    requested_by.present?
  end
end
