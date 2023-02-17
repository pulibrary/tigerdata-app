# frozen_string_literal: true
# config valid for current version and patch releases of Capistrano
lock "~> 3.17.1"

set :application, "tigerdata"
set :repo_url, "https://github.com/pulibrary/tiger-data-app.git"

set :deploy_to, "/opt/tigerdata"

set :branch, ENV["BRANCH"] || "main"

desc "Write the current version to public/version.txt"
task :write_version do
  on roles(:app), in: :sequence do
    within repo_path do
      execute :tail, "-n1 ../revisions.log > #{release_path}/public/version.txt"
    end
  end
end
after "deploy:log_revision", "write_version"
