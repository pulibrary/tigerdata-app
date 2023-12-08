# frozen_string_literal: true

set :application, "tigerdata"
set :repo_url, "https://github.com/pulibrary/tiger-data-app.git"

set :deploy_to, "/opt/tigerdata"

set :branch, ENV["BRANCH"] || "main"

set :linked_dirs, %w[log public/system public/assets node_modules]

set :yarn_flags, "--silent"

desc "Write the current version to public/version.txt"
task :write_version do
  on roles(:app), in: :sequence do
    within repo_path do
      execute :tail, "-n1 ../revisions.log > #{release_path}/public/version.txt"
    end
  end
end
after "deploy:log_revision", "write_version"

# rubocop:disable Rails/Output
namespace :mailcatcher do
  desc "Opens Mailcatcher Consoles"
  task :console do
    on roles(:app) do |host|
      mail_host = host.hostname
      user = "pulsys"
      port = rand(9000..9999)
      puts "Opening #{mail_host} Mailcatcher Console on port #{port} as user #{user}"
      Net::SSH.start(mail_host, user) do |session|
        session.forward.local(port, "localhost", 1080)
        puts "Press Ctrl+C to end Console connection"
        `open http://localhost:#{port}/`
        session.loop(0.1) { true }
      end
    end
  end
end

before "deploy:reverted", "npm:install"
# rubocop:enable Rails/Output
