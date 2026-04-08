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

# path=princeton/tigerdata/RDSS/Query/CProject
def test_project_from_path(path)
  metadata = Mediaflux::AssetMetadataRequest.new(session_token: SystemUser.mediaflux_session, id: "path=#{path}").metadata
  id = metadata[:id]
  data_sponsor = metadata[:data_sponsor]
  data_manager = metadata[:data_manager]
  FactoryBot.create(:user, uid: data_sponsor) unless User.where(uid: data_sponsor).exists?
  FactoryBot.create(:user, uid: data_manager) unless User.where(uid: data_manager).exists?
  FactoryBot.create(:project, mediaflux_id: id, data_sponsor:, data_manager: )
end
