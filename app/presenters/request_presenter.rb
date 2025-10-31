# frozen_string_literal: true
class RequestPresenter
  attr_reader :request
  def initialize(request)
    @request = request
  end

  def eligible_to_edit?(user)
    return false if user.nil?
    if request.submitted?
      user.eligible_sysadmin?
    else
      user.uid == request.requested_by || user.eligible_sysadmin?
    end
  end

  def data_sponsor
    full_name(request.data_sponsor)
  end

  def data_manager
    full_name(request.data_manager)
  end

  def project_directory
    request.parent_folder.present? ? File.join(request.parent_folder, request.project_folder) : request.project_folder
  end

  def departments_list
    return "" if request.departments.blank?
    dept_list = []
    request.departments.each do |dept|
      dept_list << "#{dept['name']} (#{dept['code']})"
    end
    dept_list.join(", ")
  end

  def user_list
    return "" if request.user_roles.blank?
    usr_list = []
    request.user_roles.each do |usr|
      usr_list << "#{full_name(usr['uid'])} #{usr['role']}"
    end
    usr_list.join(", ")
  end

  def full_name(uid)
    return "" if uid.blank?
    user = User.find_by(uid: uid)
    user.display_name_safe.to_s
  end

  # Returns the correct CSS class suffix for the sidebar navigation progress for a given
  # step/substep.
  def sidebar_progress(controller, step, substep = nil)
    controller_name = controller.controller_name
    case step
    when 1
      step1_css_suffix(controller_name, substep)
    when 2
      step2_css_suffix(controller_name)
    when 3
      step3_css_suffix(controller_name)
    when 4
      step4_css_suffix(controller_name)
    else
      "-incomplete"
    end
  end

  private

    def step1_css_suffix(controller_name, substep = nil)
      css_suffix = "-incomplete"
      if substep.nil?
        return "-current" if controller_name.start_with?("project_information")
        if step1_valid?
          css_suffix = "-completed"
        end
      elsif substep == "Basic Details"
        return "-current" if controller_name == "project_information"
        if step1_valid?
          css_suffix = "-completed"
        end
      end
      css_suffix
    end

    def step2_css_suffix(controller_name)
      return "-current" if controller_name == "roles_and_people"
      if step2_valid?
        "-completed"
      else
        "-incomplete"
      end
    end

    def step3_css_suffix(controller_name)
      return "-current" if controller_name == "storage_and_access"
      if step3_valid?
        "-completed"
      else
        "-incomplete"
      end
    end

    def step4_css_suffix(controller_name)
      return "-current" if controller_name == "review_and_submit"
      if step4_valid?
        "-completed"
      else
        "-incomplete"
      end
    end

    def step1_valid?
      return false if request.project_title.blank? || request.project_folder.blank? || request.project_purpose.blank? || request.description.blank? || request.departments.blank?
      true
    end

    def step2_valid?
      return false if request.data_manager.blank? || request.data_sponsor.blank?
      true
    end

    def step3_valid?
      return false if request.storage_size.nil?
      true
    end

    def step4_valid?
      step1_valid? && step2_valid? && step3_valid?
    end
end
