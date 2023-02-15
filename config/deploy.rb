# frozen_string_literal: true
# config valid for current version and patch releases of Capistrano
lock "~> 3.17.1"

set :application, "tigerdata"
set :repo_url, "https://github.com/pulibrary/tiger-data-app.git"

set :deploy_to, "/opt/tigerdata"

set :branch, ENV["BRANCH"] || "main"
