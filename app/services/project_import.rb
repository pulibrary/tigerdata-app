require "csv"

class ProjectImport

    attr_accessor :csv_data, :test_run

    def initialize(csv_data, test_run: false)
        @csv_data = csv_data
        @test_run = test_run
    end

    def self.run_with_report(mediaflux_session:)
      report = Mediaflux::ProjectReport.new(session_token: mediaflux_session)
      return [report.response_error[:message]] if report.error?

      importer = self.new(report.csv_data.gsub("\r\n",""))
      importer.run
    end

    def run
        output = []
        mediaflux_projects = CSV.new(csv_data, headers: true, liberal_parsing: true)
        mediaflux_projects.each do |project_metadata|
          # skip projects not part of the current namespace in dev & test mode since we have both mediaflux instances in one server
          if Rails.env.development? || Rails.env.test?
            next unless project_metadata["path"].starts_with?(Rails.configuration.mediaflux["api_root_collection_namespace"])
          end
          project_id = project_metadata["projectID"]
          existing_project = Project.where("metadata_json @> ?", JSON.dump(project_id:))
          if existing_project.count > 0
            output << "Skipping project #{project_id}.  There are already #{existing_project.count} version of that project in the system"
          else
            metadata = convert_csv(project_metadata:, project_id:)
            if test_run
              output << metadata.to_json
            else
              project = Project.create(metadata:, mediaflux_id: project_metadata["asset"])
              if (project.valid?)
                output << "Created project for #{project_id}"
              else
                output << "Error creating project for #{project_metadata["asset"]}: #{project.errors.to_a.join(";")}"
              end
            end
          end
        end
        output
    rescue CSV::MalformedCSVError => error
      ["Error parsing response #{ csv_data.to_s.slice(0,200) } error: #{error}"]
    end

    private
        def convert_csv(project_metadata:, project_id:)
            data_user = parse_multiple(project_metadata, "dataUser")
            department_names = parse_multiple(project_metadata,"department")
            departments = department_names.map {|name| Affiliation.find_fuzzy_by_name(name)&.code || name }

            storage_size_gb = project_metadata["quota"].downcase.to_f/1000000000.0
            ProjectMetadata.new_from_hash({
              project_id:,
              title: project_metadata["title"],
              description: project_metadata["description"],
              status: Project::ACTIVE_STATUS,
              data_sponsor: project_metadata["dataSponsor"],
              data_manager: project_metadata["dataManager"],
              departments: departments,
              data_user_read_only: data_user,
              project_directory: project_metadata["path"],
              storage_capacity: {size: { approved: storage_size_gb, requested: storage_size_gb}, unit: {approved: "GB", requested: "GB"}},
              storage_performance_expectations: { requested: "Standard", approved: "Standard" },
              created_by: project_metadata["creatorUser"],
              created_on: project_metadata["createdOn"]
            })
        end

        def parse_multiple(project_metadata, key)
            if project_metadata[key].blank?
            []
            else
            project_metadata[key].split(",").map(&:strip)
            end
        end
end