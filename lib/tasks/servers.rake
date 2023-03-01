# frozen_string_literal: true
namespace :servers do
  task initialize: :environment do
    Rake::Task["db:setup"].invoke
  end

  desc "Starts development dependencies"
  task start: :environment do
    system("lando start")
    system("rake servers:initialize")
    system("rake servers:initialize RAILS_ENV=test")
  end

  desc "Stop development dependencies"
  task stop: :environment do
    system "lando stop"
  end
end
