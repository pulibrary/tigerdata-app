# frozen_string_literal: true
namespace :mediaflux do
  desc "Delete everything from the current environment (use with caution)"
  task destructive_cleanup: :environment do
    raise "You can't run this in production!" if Rails.env.production?
    login = Mediaflux::LogonRequest.new
    login.resolve
    session_id = login.session_token
    message = "Deleting everything from mediaflux namespace: #{Rails.configuration.mediaflux[:api_root_to_clean]}"
    puts message
    Rails.logger.warn message
    Mediaflux::NamespaceDestroyRequest.new(session_token: session_id, namespace: Rails.configuration.mediaflux[:api_root_to_clean]).destroy
    [UserRequest, User, Project].each(&:delete_all)
    puts "All users, projects, and mediaflux data deleted."
    Rails.logger.warn "All users, projects, and mediaflux data deleted."
  end
end
