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
    raise "User id must be specified" if uid.blank?
    user = User.find_by(uid:)
    raise "User #{uid} not found" if user.nil?
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

  desc "Outputs to a file an aterm script to create a project (namespace and collection) in Mediaflux"
  task :create_script, [:project_id] => [:environment] do |_, args|
    project_id = args[:project_id]
    project = Project.find(project_id)

    project_directory = project.metadata_json["directory"]
    project_parent = Rails.configuration.mediaflux['api_root_collection']
    path_id = "#{project_parent}/#{project_directory}"
    project_namespace = "#{Rails.configuration.mediaflux['api_root_ns']}/#{project_directory}NS"
    department_fields = project.metadata_json["departments"].map { |department| ":Department \"#{department}\"" }
    created_on = Time.parse(project.metadata_json["created_on"]).strftime("%e-%b-%Y %H:%M:%S").upcase

    script = <<-ATERM
      # Run these steps from Aterm to create a project in Mediaflux with its related components

      # Create the namespace for the project
      asset.namespace.create :namespace #{project_namespace}

      # Create the collection asset for the project
      asset.create
        :pid #{project_parent}
        :namespace #{project_namespace}
        :name #{project.metadata_json["directory"]}
        :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true
        :type "application/arc-asset-collection"
        :meta <
          :tigerdata:project <
            :Code "#{project_directory}"
            :Title "#{project.metadata_json["title"]}"
            :Description "#{project.metadata_json["description"]}"
            :Status "#{project.metadata_json["status"]}"
            :DataSponsor "#{project.metadata_json["data_sponsor"]}"
            :DataManager "#{project.metadata_json["data_manager"]}"
            #{department_fields.join(" ")}
            :CreatedOn "#{created_on}"
            :CreatedBy "#{project.metadata_json["created_by"]}"
            :ProjectID "#{project.metadata_json["project_id"]}"
            :StorageCapacity < :Size "#{project.metadata_json["storage_capacity"]["size"]["requested"]}>" :Unit #{project.metadata_json["storage_capacity"]["unit"]["requested"]}"
            :StoragePerformance "#{project.metadata_json["storage_performance_expectations"]["requested"]}"
            :ProjectPurpose "#{project.metadata_json["project_purpose"]}"
          >
        >

    # Define accumulator for file count
    asset.collection.accumulator.add
      :id path=#{path_id}
      :cascade true
      :accumulator <
        :name #{project_directory}-count
        :type collection.asset.count
      >

    # Define accumulator for total file size
    asset.collection.accumulator.add
      :id path=#{path_id}
      :cascade true
      :accumulator <
      :name #{project_directory}-size
        :type content.all.size
      >

    # Define storage quota
    asset.collection.quota.set
      :id path=#{path_id}
      :quota < :allocation 500 GB :on-overflow fail :description "500 GB quota for #{project_directory}>"

    ATERM

    file_name = "project_create_#{project.id}.txt"
    puts "Saving script to #{file_name}"
    File.write(file_name, script)
  end

  task :download_file_list, [:netid, :project_id] => [:environment] do |_, args|
    netid = args[:netid]
    user = User.where(uid: netid).first
    raise "User #{netid} not found" if user.nil?

    project_id = args[:project_id]
    project = Project.find(project_id)
    filename = "file_list_#{project_id}.csv"
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
    start_time = Time.current.in_time_zone("America/New_York").iso8601
    yield
    end_time = Time.current.in_time_zone("America/New_York").iso8601
    sec = end_time.to_f - start_time.to_f
    ms_display = format("%.2f", sec * 1000)
    sec_display = format("%.2f", sec)
    puts "#{label} #{ms_display} ms #{sec_display} seconds"
  end
end
# :nocov:
