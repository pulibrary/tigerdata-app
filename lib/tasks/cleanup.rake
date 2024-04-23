# frozen_string_literal: true
namespace :cleanup do
  desc "Delete everything from the current environment (use with caution)"
  task everything: :environment do
    raise "You can't run this in production!" if Rails.env.production?
    login = Mediaflux::Http::LogonRequest.new
    login.resolve
    session_id = login.session_token
    byebug
    Mediaflux::Http::NamespaceDestroyRequest.new(session_token: session_id, namespace: Rails.configuration.mediaflux[:api_root_ns]).destroy
    [User, Project].each(&:delete_all)
  end
end
