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
     full_name(request.data_sponsor)
  end
  def full_name(uid)
    return "" if uid.nil?
    user = User.find_by(uid: uid)
    user.display_name_safe.to_s
  end
end
