# frozen_string_literal: true
namespace :load_affiliations do
  desc "Load department affiliations from a file"
  task :from_file, [:department_file] => [:environment] do |_, args|
    Affiliation.load_from_file(args[:department_file])
  end
end
