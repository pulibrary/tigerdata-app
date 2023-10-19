# frozen_string_literal: true
namespace :projects do
  desc "Create many test projects"
  task create_many: :environment do
    (1..100).each do |i|
      sequence = i.to_s.rjust(5, "0")
      user = User.first

      project = Project.new
      project.created_by_user = user
      project.metadata = {
        data_sponsor: "xx123",
        data_manager: "yy123",
        departments: ["PUL", "RDSS"],
        directory: "project-#{sequence}",
        title: "Project #{sequence}",
        description: "Description of project #{sequence}",
        data_user_read_only: [],
        data_user_read_write: []
      }
      project.save!

      project.approve!(session_id: user.mediaflux_session, created_by: user.uid)
    end
  end
end
