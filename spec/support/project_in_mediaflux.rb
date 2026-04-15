# frozen_string_literal: true
def create_project_in_mediaflux(request: nil, current_user: nil)
  request ||= FactoryBot.create(:request_project)
  tigerdatatester = User.where(uid: "tigerdatatester").first || FactoryBot.create(:user, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session  )
  current_user ||= tigerdatatester
  current_user.mediaflux_session ||= SystemUser.mediaflux_session
  project = request.approve(current_user)
  request.destroy!
  project
end

# path=princeton/tigerdata/RDSS/Query/CProject
def test_project_from_path(path)
  metadata = Mediaflux::AssetMetadataRequest.new(session_token: SystemUser.mediaflux_session, id: "path=#{path}").metadata
  id = metadata[:id]
  raise StandardError, "Project not found in Mediaflux #{path}" if id.blank?
  data_sponsor = metadata[:data_sponsor] || "tigerdatatester"
  data_manager = metadata[:data_manager] || "tigerdatatester"
  data_users = metadata[:data_users]
  FactoryBot.create(:user, uid: data_sponsor) unless User.where(uid: data_sponsor).exists?
  FactoryBot.create(:user, uid: data_manager) unless User.where(uid: data_manager).exists?
  data_users = metadata[:data_users]
  data_users&.each do |user_uid|
    FactoryBot.create(:user, uid: user_uid) unless User.where(uid: user_uid).exists?
  end
  byebug if metadata[:title].nil?
  FactoryBot.create(:project, mediaflux_id: id, data_sponsor:, data_manager:, project_directory: path, title: metadata[:title])
end
