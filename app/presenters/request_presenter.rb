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
end
