# frozen_string_literal: true
namespace :projects do
  desc "Times the creation of projects and querying by TigerData metadata fields"
  task :create_many, [:count, :prefix] => [:environment] do |_, args|
    count = (args[:count] || "").to_i
    project_prefix = args[:prefix]
    raise "Count must be specified" if count == 0
    raise "Project prefix must be specified" if project_prefix.nil?

    user = User.first
    Organization.create_defaults(session_id: user.mediaflux_session)

    time_action("Creating projects") do
      puts "Creating #{count} projects with prefix #{project_prefix}..."
      (1..count).each do |i|
        project = create_test_project(i, user, project_prefix)
        project.save!
        project.approve!(session_id: user.mediaflux_session, created_by: user.uid)
        puts i if (i % 100) == 0
      end
    end

    query_test_projects(user)
  end

  task :query, [:data_sponsor, :department] => [:environment] do |_, args|
    data_sponsor = args[:data_sponsor]
    department = args[:department]
    user = User.first
    Organization.create_defaults(session_id: user.mediaflux_session)

    time_action("Getting counts by data_sponsor #{data_sponsor} department #{department} took") do
      count_request = Mediaflux::Http::CollectionCountRequest.new(
        session_token: user.mediaflux_session, namespace: "/td-demo-001", data_sponsor: data_sponsor, department: department
      )
      count_request.resolve
      puts "#{count_request.count} records for #{data_sponsor} department #{department}"
    end
  end

  # rubocop:disable Metrics/MethodLength
  def create_test_project(number, user, project_prefix)
    sequence = number.to_s.rjust(5, "0")
    sponsor = if (number % 7) == 0
                "zz007"
              elsif (number % 3) == 0
                "zz003"
              else
                "zz001"
              end
    departments = []
    departments << "SEVEN" if (number % 7) == 0
    departments << "THREE" if (number % 3) == 0
    departments << "FIVE" if (number % 5) == 0
    departments << "ONE" if departments.count == 0

    project = Project.new
    project.created_by_user = user
    project.metadata = {
      data_sponsor: sponsor,
      data_manager: "zz789",
      departments: departments,
      directory: "#{project_prefix}-#{sequence}",
      title: "Project #{project_prefix} #{sequence}",
      description: "Description of project #{project_prefix} #{sequence}",
      data_user_read_only: [],
      data_user_read_write: []
    }
    project
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def query_test_projects(user)
    counts = []
    ["zz001", "zz003", "zz007", nil].each do |data_sponsor|
      time_action("Getting counts by data_sponsor #{data_sponsor}") do
        count_request = Mediaflux::Http::CollectionCountRequest.new(session_token: user.mediaflux_session, namespace: "/td-demo-001", data_sponsor: data_sponsor)
        count_request.resolve
        counts << { data_sponsor: data_sponsor || "total", count: count_request.count }
      end
    end
    puts counts

    total73 = 0
    time_action("Getting counts by data_sponsor zz007 department THREE") do
      count_request = Mediaflux::Http::CollectionCountRequest.new(session_token: user.mediaflux_session, namespace: "/td-demo-001", data_sponsor: "zz007", department: "THREE")
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
    ms_display = format("%.2f", sec * 100)
    sec_display = format("%.2f", sec)
    puts "#{label} #{ms_display} ms #{sec_display} seconds"
  end
end
