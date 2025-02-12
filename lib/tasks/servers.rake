# frozen_string_literal: true
# :nocov:

namespace :servers do
  task initialize: :environment do
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end

  desc "Starts development dependencies"
  task start: :environment do
    system("docker compose up -d")
    system("rake servers:initialize")
    system("rake servers:initialize RAILS_ENV=test")
    system("rake load_users:from_registration_list")
    system("rake load_affiliations:from_file[spec/fixtures/departments.csv]")
  end

  desc "Stop development dependencies"
  task stop: :environment do
    system "docker compose down"
  end
end
# :nocov:
