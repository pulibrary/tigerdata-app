# frozen_string_literal: true
# :nocov:

namespace :servers do
  task install_mediaflux: :environment do
    system("docker create --name mediaflux --mac-address 02:42:ac:11:00:02 --publish 8888:80 pulibraryrdss/mediaflux_dev:v0.10.0")
    system("docker start mediaflux")
  end

  task initialize: :environment do
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end

  desc "Starts development dependencies"
  task start: :environment do
    system("lando start")
    system("rake servers:install_mediaflux")
    system("rake servers:initialize")
    system("rake servers:initialize RAILS_ENV=test")
    system("rake load_users:rdss_developers")
    system("rake load_affiliations:from_file[spec/fixtures/departments.csv]")
    system("rake servers:dev_admin_users") # TODO: remove when closing https://github.com/pulibrary/tigerdata-app/issues/1652
  end

  desc "Stop development dependencies"
  task stop: :environment do
    system "lando stop"
  end

  # TODO: remove when closing https://github.com/pulibrary/tigerdata-app/issues/1652
  desc "Make sure the developer accounts are administrators"
  task dev_admin_users: :environment do
    login = Mediaflux::LogonRequest.new
    login.resolve

    type = "role"
    name = "pu-lib:developer"
    role = "system-administrator"
    grant_role_request = Mediaflux::ActorGrantRoleRequest.new(session_token: login.session_token, type:, name:, role:)
    grant_role_request.resolve
    if grant_role_request.error?
      puts "ERROR: #{grant_role_request.response_body}"
    end
  end
end
# :nocov:
