# frozen_string_literal: true
# :nocov:

namespace :servers do
  task install_mediaflux: :environment do
    system("docker create --name mediaflux --mac-address 02:42:ac:11:00:02 --publish 8888:80 pulibraryrdss/mediaflux_dev:v0.19.0")
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
  end

  desc "Stop development dependencies"
  task stop: :environment do
    system "lando stop"
    system("docker stop mediaflux")
    puts "docker ps:"
    system("docker ps")
  end
end
# :nocov:
