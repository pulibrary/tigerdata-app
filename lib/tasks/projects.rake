# frozen_string_literal: true
# :nocov:
namespace :projects do
  desc "Times the creation of projects and querying by TigerData metadata fields"
  task :create_many, [:count, :prefix] => [:environment] do |_, args|
    raise "Count must be specified" if count.blank?
    count = args[:count].to_i
    project_prefix = args[:prefix]
    raise "Project prefix must be specified" if project_prefix.nil?

    user = User.first
    Organization.create_defaults(session_id: user.mediaflux_session)
    root_ns = Rails.configuration.mediaflux["api_root_ns"]

    time_action("Creating projects") do
      puts "Creating #{count} projects with prefix #{project_prefix}..."
      (1..count).each do |i|
        project_generator = TestProjectGenerator.new(user:, number: i, project_prefix:)
        project_generator.generate
        puts i if (i % 100) == 0
      end
    end

    query_test_projects(user, root_ns)
  end

  desc "Create a test project and a small number of assets in that project"
  task :create_small_project, [:uid, :prefix] => [:environment] do |_, args|
    uid = args[:uid]
    raise "Count must be specified" if uid.blank?
    user = User.find_by(uid:)
    project_prefix = args[:prefix]
    raise "Project prefix must be specified" if project_prefix.nil?
    number = rand(10_000)
    project_generator = TestProjectGenerator.new(user:, number: number, project_prefix:)
    project = project_generator.generate
    puts "Project created #{project.id}.  Saved in mediaflux under #{project.mediaflux_id}"
    levels = rand(10)
    directory_per_level = rand(10)
    file_count_per_directory = rand(10)
    asset_generator = TestAssetGenerator.new(user:, project_id: project.id, levels:, directory_per_level:, file_count_per_directory:)
    asset_generator.generate
    puts "Assets were generated in mediaflux under #{project.mediaflux_id}.  #{levels} levels with #{directory_per_level} directories per levels and #{file_count_per_directory} files in each directory"
  end


  task :query, [:data_sponsor, :department] => [:environment] do |_, args|
    data_sponsor = args[:data_sponsor]
    department = args[:department]
    root_ns = Rails.configuration.mediaflux["api_root_ns"]

    user = User.first
    Organization.create_defaults(session_id: user.mediaflux_session)

    time_action("Getting counts by data_sponsor #{data_sponsor} department #{department} took") do
      count_request = Mediaflux::Http::CollectionCountRequest.new(
        session_token: user.mediaflux_session, namespace: root_ns, data_sponsor: data_sponsor, department: department
      )
      count_request.resolve
      puts "#{count_request.count} records for #{data_sponsor} department #{department}"
    end
  end

  task :save_in_mediaflux, [:netid, :project_id] => [:environment] do |_, args|
    netid = args[:netid]
    user = User.where(uid: netid).first
    raise "User #{netid} not found" if user.nil?

    project_id = args[:project_id]
    project = Project.find(project_id)
    asset_id = project.save_in_mediaflux(session_id: user.mediaflux_session)
    puts "Mediaflux asset #{asset_id} updated"
  end

  task :download_file_list, [:netid, :project_id] => [:environment] do |_, args|
    netid = args[:netid]
    user = User.where(uid: netid).first
    raise "User #{netid} not found" if user.nil?

    project_id = args[:project_id]
    project = Project.find(project_id)
    filename = "file_list_#{project_id}.txt"
    puts "Downloading file list for project #{project_id}"
    time_action("download file list") do
      asset_id = project.file_list_to_file(session_id: user.mediaflux_session, filename: filename)
    end
    puts "File list downloaded for project #{project_id}"
  end

  # rubocop:disable Metrics/MethodLength
  def query_test_projects(user, root_ns)
    counts = []
    ["zz001", "zz003", "zz007", nil].each do |data_sponsor|
      time_action("Getting counts by data_sponsor #{data_sponsor}") do
        count_request = Mediaflux::Http::CollectionCountRequest.new(session_token: user.mediaflux_session, namespace: root_ns, data_sponsor: data_sponsor)
        count_request.resolve
        counts << { data_sponsor: data_sponsor || "total", count: count_request.count }
      end
    end
    puts counts

    total73 = 0
    time_action("Getting counts by data_sponsor zz007 department THREE") do
      count_request = Mediaflux::Http::CollectionCountRequest.new(session_token: user.mediaflux_session, namespace: root_ns, data_sponsor: "zz007", department: "THREE")
      count_request.resolve
      total73 = count_request.count
    end
    puts "#{total73} records for data_sponsor zz007 department THREE"
  end
  # rubocop:enable Metrics/MethodLength

  def time_action(label)
    start_time = DateTime.now
    yield
    end_time = DateTime.now
    sec = end_time.to_f - start_time.to_f
    ms_display = format("%.2f", sec * 1000)
    sec_display = format("%.2f", sec)
    puts "#{label} #{ms_display} ms #{sec_display} seconds"
  end
end
# :nocov:
