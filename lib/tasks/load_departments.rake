# frozen_string_literal: true
namespace :load_affiliations do
  desc "Load in users from the registration list"
  task :from_file, [:department_file] => [:environment] do |_, args|
    Affiliation.load_from_file(args[:department_file])
  end
end
