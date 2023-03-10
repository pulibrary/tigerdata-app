# frozen_string_literal: true
# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

set :branch, ENV["BRANCH"] || :main

server "tigerdata-staging1", user: "deploy", roles: %w[app db web]
server "tigerdata-staging2", user: "deploy", roles: %w[app db web]
