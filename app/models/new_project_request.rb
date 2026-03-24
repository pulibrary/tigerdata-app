# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
# Represents a new project request with validation and approval logic.
class NewProjectRequest < ApplicationRecord
  DRAFT = "draft" # default state set by database
  SUBMITTED = "submitted" # Ready to be approved

  # Validates if the request is valid to submit.
  # @param allow_empty_parent_folder [Boolean] whether to allow empty parent folder.
  # @return [Boolean] true if no errors, false otherwise.
  def valid_to_submit?(allow_empty_parent_folder: false)
    errors.clear
    # run all validations and then check for errors otherwise ruby stops at the first error
    valid_title?
    valid_data_sponsor?
    valid_data_manager?
    valid_departments?
    valid_quota?
    valid_project_purpose?
    valid_description?
    valid_parent_folder?(allow_empty_parent_folder:)
    valid_project_folder?
    # For Skeletor we are setting the requestor to the data sponsor
    # valid_requested_by?
    errors.count == 0
  end

  # Validates the project title.
  # @return [Boolean] true if valid, false otherwise.
  def valid_title?
    check_errors? do
      field_present?(project_title, :project_title)
      valid_length(project_title, 200, :project_title)
    end
  end

  # Validates the data sponsor.
  # @return [Boolean] true if valid, false otherwise.
  def valid_data_sponsor?
    check_errors? { validate_uid(data_sponsor, :data_sponsor) }
  end

  # Validates the data manager.
  # @return [Boolean] true if valid, false otherwise.
  def valid_data_manager?
    check_errors? { validate_uid(data_manager, :data_manager) }
  end

  # Validates the departments.
  # @return [Boolean] true if valid, false otherwise.
  def valid_departments?
    check_errors? { field_present?(departments, :departments) }
  end

  # Validates the project purpose.
  # @return [Boolean] true if valid, false otherwise.
  def valid_project_purpose?
    check_errors? { project_purpose_present?(project_purpose, :project_purpose) }
  end

  # Validates the description.
  # @return [Boolean] true if valid, false otherwise.
  def valid_description?
    check_errors? do
      field_present?(description, :description)
      valid_length(description, 1000, :description)
    end
  end

  # Validates the parent folder.
  # @param allow_empty_parent_folder [Boolean] whether to allow empty parent folder.
  # @return [Boolean] true if valid, false otherwise.
  def valid_parent_folder?(allow_empty_parent_folder: false)
    check_errors? do
      field_present?(parent_folder, :parent_folder) unless allow_empty_parent_folder
      # Check the parent_folder for invalid characters.
      alphanumeric_dash_underscore_only(parent_folder, :parent_folder)
    end
  end

  # Validates the project folder.
  # @return [Boolean] true if valid, false otherwise.
  def valid_project_folder?
    check_errors? do
      field_present?(project_folder, :project_folder)
      # Check the project folder for invalid characters (notice that we display the error under the parent folder)
      alphanumeric_dash_underscore_only(project_folder, :parent_folder)
    end
  end

  # Validates the quota.
  # @return [Boolean] true if valid, false otherwise.
  def valid_quota?
    if ((quota == "500 GB") || (quota == "2 TB") || (quota == "10 TB") || (quota == "25 TB")) ||
       (custom_quota? && (storage_size.present? && (storage_size > 0)) && ((storage_unit == "GB") || (storage_unit == "TB")))
      true
    else
      errors.add(:quota, :invalid, message: "must be one of '500 GB', '2 TB', '10 TB', '25 TB', or 'custom'")
      false
    end
  end

  # Checks if quota is custom.
  # @return [Boolean] true if quota is 'custom', false otherwise.
  def custom_quota?
    quota == "custom"
  end

  # Validates the requested by.
  # @return [Boolean] true if valid, false otherwise.
  def valid_requested_by?
    check_errors? { field_present?(requested_by, :requested_by) }
  end

  # Approves the project request.
  # @param approver [User] the user approving the request.
  # @return [Project] the created project.
  # @raise [ProjectCreate::ProjectCreateError] if approval fails.
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

  # Gets the approved quota size.
  # @return [Float] the approved quota size.
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

  # Gets the requested quota size.
  # @return [Float] the requested quota size.
  def requested_quota_size
    if custom_quota?
      storage_size.to_f
    else
      quota.split.first.to_f
    end
  end

  # Gets the approved quota unit.
  # @return [String] the approved quota unit.
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

  # Gets the requested quota unit.
  # @return [String] the requested quota unit.
  def requested_quota_unit
    if custom_quota?
      storage_unit
    else
      quota.split.last
    end
  end

  # Checks if the request is submitted.
  # @return [Boolean] true if state is SUBMITTED, false otherwise.
  def submitted?
    state == NewProjectRequest::SUBMITTED
  end

  # Gets the project path.
  # @return [String] the project path.
  def project_path
    return project_folder if parent_folder.blank?

    [parent_folder, project_folder].join("/")
  end

  # Gets the requestor name.
  # @return [String] the requestor display name.
  def requestor
    return "Missing requestor." if requested_by.blank?
    User.find_by(uid: requested_by).display_name_safe
  end

  # Gets the data manager name.
  # @return [String] the data manager name.
  def data_manager_name
    user_name(data_manager)
  end

  # Gets the data sponsor name.
  # @return [String] the data sponsor name.
  def data_sponsor_name
    user_name(data_sponsor)
  end

  private

    # Gets the display name for a user by uid.
    # @param uid [String] the user id.
    # @return [String] the display name or uid if not found.
    def user_name(uid)
      return "" if uid.blank?
      user = User.find_by(uid: uid)
      if user.present?
        user.display_name_safe
      else
        uid
      end
    end

    # Checks if errors are added during the block.
    # @return [Boolean] true if no new errors, false otherwise.
    # @yield [] the block to execute.
    def check_errors?
      original_error_count = errors.count
      yield
      original_error_count == errors.count
    end

    # Adds error if value is blank.
    # @param value [Object] the value to check.
    # @param name [Symbol] the field name for error.
    # @return [void]
    def field_present?(value, name)
      if value.blank?
        errors.add(name, :invalid, message: "This field is required.")
      end
    end

    # Validates if uid is present and valid user.
    # @param uid [String] the user id.
    # @param field [Symbol] the field name.
    # @return [void]
    def validate_uid(uid, field)
      if uid.blank?
        errors.add(field, :blank, message: "This field is required.")
      elsif User.where(uid: uid).count == 0
        errors.add(field, :invalid, message: "Must be a valid user.")
      end
    end

    # Adds error if project purpose is blank.
    # @param project_purpose [String] the purpose.
    # @param field [Symbol] the field name.
    # @return [void]
    def project_purpose_present?(project_purpose, field)
      if project_purpose.blank?
        errors.add(field, :blank, message: "Select a project purpose.")
      end
    end

    # Validates the length of value.
    # @param value [String] the value.
    # @param length [Integer] the max length.
    # @param field [Symbol] the field name.
    # @return [void]
    def valid_length(value, length, field)
      return if value.blank?
      if value.length > length
        errors.add(field, :invalid, message: "Value is too long. The maximum allowed is #{length} characters, current value is #{value.length} characters long.")
      end
    end

    # Validates the value for allowed characters.
    # Allows alphanumeric, dashes, underscores, and forward-slashes
    # @param value [String] the value.
    # @param field [Symbol] the field name.
    # @return [void]
    def alphanumeric_dash_underscore_only(value, field)
      return if value.blank?
      if value.match(/\A[\w\-\/]+\z/).nil?
        errors.add(field, :invalid, message: "Only letters, numbers, dashes, and underscores are allowed.")
      elsif value.include?("//")
        errors.add(field, :invalid, message: "Empty subfolders are not allowed.")
      elsif value.start_with?("/")
        errors.add(field, :invalid, message: "Cannot start with a forward slash.")
      elsif value.end_with?("/")
        errors.add(field, :invalid, message: "Cannot end with a forward slash.")
      end
    end

    # If a request fails to be a approved we make sure there were not orphan
    # project records left in our Rails database that do not have a matching
    # project in Mediaflux (i.e. collection asset).
    # @return [void]
    def cleanup_incomplete_project
      project = Project.find_by_id(project_id)
      if project && project.mediaflux_id.nil?
        Rails.logger.warn("Deleting project #{project.id} because the approval for request #{id} failed and it was not created in Mediaflux.")
        project.destroy!
      end
    end
end
# rubocop:enable Metrics/ClassLength
