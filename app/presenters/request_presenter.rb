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

  def full_name(uid)
    return "" if uid.blank?
    user = User.find_by(uid: uid)
    user.display_name_safe.to_s
  end

  def sidebar_progress(controller, step, substep = nil)
    controller_name = controller.controller_name

    if step == 1 && substep.nil?
      if controller_name.start_with?('project_information')
        return "-current"
      else
        if valid_step1?
          return "-completed"
        else
          return "-incomplete"
        end
      end
    end

    if step == 1 && substep == "Basic Details"
      if controller.controller_name == 'project_information'
        return "-current"
      else
        if valid_step1?
          return "-completed"
        else
          return "-incomplete"
        end
      end
    end

    if step == 2
      if controller_name == 'roles_and_people'
        return "-current"
      else
        if valid_step2?
          return "-completed"
        else
          return "-incomplete"
        end
      end
    end

    if step == 3
      if controller_name == 'storage_and_access'
        return "-current"
      else
        # TODO: We should return incomplete unless the user has at least visited this step
        return "-completed"
      end
    end

    if step == 4
      if controller_name == 'review_and_submit'
        return "-current"
      else
        if valid_step4?
          return "-completed"
        else
          return "-incomplete"
        end
      end
    end

    return "-incomplete"
  end

  private

    def valid_step1?
      return false if request.project_title.blank? || request.project_folder.blank? || request.project_purpose.blank? || request.description.blank? || request.departments.blank?
      true
    end

    def valid_step2?
      return false if request.data_manager.blank? || request.data_sponsor.blank?
      true
    end

    def valid_step3?
      true
    end

    def valid_step4?
      valid_step1? && valid_step2? && valid_step3?
    end
end
