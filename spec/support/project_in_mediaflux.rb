def project_in_mediaflux(request: nil, current_user: nil)
    request ||= FactoryBot.create(:request_project)
    current_user ||= FactoryBot.create(:sysadmin, uid: "tigerdatatester")
    project = request.approve(current_user)
    request.destroy!
    project
end
