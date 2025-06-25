# frozen_string_literal: true

set :application, "tigerdata"
set :repo_url, "https://github.com/pulibrary/tigerdata-app.git"

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

namespace :application do
  # You can/ should apply this command to a single host
  # cap --hosts=tigerdata-staging1.lib.princeton.edu staging application:remove_from_nginx
  desc "Marks the server(s) to be removed from the loadbalancer"
  task :remove_from_nginx do
    count = 0
    on roles(:app) do
      count += 1
    end
    if count > (roles(:app).length / 2)
      raise "You must run this command on no more than half the servers utilizing the --hosts= switch"
    end
    on roles(:app) do
      within release_path do
        execute :touch, "/opt/tigerdata/shared/remove-from-nginx"
      end
    end
  end

  # You can/ should apply this command to a single host
  # cap --hosts=tigerdata-staging1.lib.princeton.edu staging application:serve_from_nginx
  desc "Marks the server(s) to be added back to the loadbalancer"
  task :serve_from_nginx do
    on roles(:app) do
      within release_path do
        execute :rm, "-f /opt/tigerdata/shared/remove-from-nginx"
      end
    end
  end
end

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

namespace :schema do
  desc "Load the current schema"
  task :load do
    on roles(:schema) do
      within release_path do
        execute("cd #{release_path} && bundle exec rake schema:create")
      end
    end
  end
end

after "deploy:published", "schema:load"

before "deploy:reverted", "npm:install"

namespace :sidekiq do
  task :restart do
    on roles(:app) do
      execute :sudo, :service, "tiger-data-workers", :restart
    end
  end

  desc "Opens Sidekiq Consoles"
  task :console do
    on roles(:app) do |host|
      sidekiq_host = host.hostname
      user = "pulsys"
      port = rand(9000..9999)
      puts "Opening #{sidekiq_host} Sidekiq Console on port #{port} as user #{user}"
      Net::SSH.start(sidekiq_host, user) do |session|
        session.forward.local(port, "localhost", 80)
        puts "Press Ctrl+C to end Console connection"
        `open http://localhost:#{port}/sidekiq`
        session.loop(0.1) { true }
      end
    end
  end
end

after "passenger:restart", "sidekiq:restart"
# rubocop:enable Rails/Output
