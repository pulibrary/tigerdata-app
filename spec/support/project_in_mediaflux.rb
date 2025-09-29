# frozen_string_literal: true
def create_project_in_mediaflux(request: nil, current_user: nil)
  request ||= FactoryBot.create(:request_project)
  current_user ||= FactoryBot.create(:sysadmin, uid: "tigerdatatester")
  tigerdatatester = User.where(uid: "tigerdatatester").first
  if tigerdatatester.blank?
    FactoryBot.create(:user, uid: "tigerdatatester")
  end
  project = request.approve(current_user)
  request.destroy!
  project
end
