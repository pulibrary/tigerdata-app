# frozen_string_literal: true
namespace :exports do
  desc "Outputs to the console a list of export files and an indication of whether they are too old"
  task :report_old, [:days] => [:environment] do |_, args|
    days = (args[:days] || "30").to_i
    pathname = Pathname.new(Rails.configuration.mediaflux["shared_files_location"])
    scan_directory(pathname.join("*.csv")).each do |file|
      puts "#{file[:name]}, #{file[:age]}, #{file[:age] > days}"
    end
  end

  desc "Deletes files that are too old (default to 30 days)"
  task :delete_old, [:days] => [:environment] do |_, args|
    days = (args[:days] || "30").to_i
    pathname = Pathname.new(Rails.configuration.mediaflux["shared_files_location"])
    scan_directory(pathname.join("*.csv")).each do |file|
      if file[:age] > days
        File.delete(file[:name])
      end
    end
  end

  private

    def scan_directory(path)
      files = []
      Dir[path].each do |filename|
        file_info = File.stat(filename)
        age_in_seconds = Time.zone.now - file_info.mtime
        age_in_days = (age_in_seconds / (60 * 60 * 24)).round
        files << { name: filename, age: age_in_days }
      end
      files
    end
end
