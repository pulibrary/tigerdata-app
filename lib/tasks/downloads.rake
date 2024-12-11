# frozen_string_literal: true
namespace :downloads do
  desc "Fake a few download records for the given netid"
  task :fake_latest, [:netid] => :environment do |_, args|
    netid = args[:netid]
    raise "Must provide a netid" if netid.blank?
    user = User.where(uid: netid).first
    projects = Project.users_projects(user)
    if projects.count == 0
      puts "There are no projects for user #{netid} :sad-trombone:"
    else
      puts "Adding fake downloads for user #{netid}..."
      projects.each do |project|
        puts "Project #{project.title} (#{project.id})"
        request = UserRequest.new(user_id: user.id, project_id: project.id, state: "completed")
        request.request_details = { "output_file" => "data.txt", "project_title" => project.title }
        request.save!
      end
    end
  end
end
