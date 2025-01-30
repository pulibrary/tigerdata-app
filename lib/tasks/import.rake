require 'csv'
# frozen_string_literal: true
#
# The input file can be created by running by running the following script in aterm:
#
# set ids [xvalues id [asset.query :where xpath(tigerdata:project/ProjectID) has value]]
# puts "asset,path,creatorDomain,creatorUser,createdOn,quota,store,projectDirectory,title,description,dataSponsor,dataManager,dataUser,department,projectID"
# foreach id $ids {
#     set asset [asset.get :id $id]
#     set path [xvalue asset/path $asset]
#     set creatorDomain [xvalue asset/creator/domain $asset]
#     set creatorUser [xvalue asset/creator/user $asset]
#     set createdOn [xvalue  asset/ctime $asset]
#     set store [xvalue asset/collection/store $asset]
#     set projectDirectory [xvalue asset/meta/tigerdata:project/ProjectDirectory $asset]
#     set title [xvalue asset/meta/tigerdata:project/Title $asset]
#     set description [xvalue asset/meta/tigerdata:project/Description $asset]
#     set dataSponsor [xvalue asset/meta/tigerdata:project/DataSponsor $asset]
#     set dataManager [xvalue asset/meta/tigerdata:project/DataManager $asset]
#     set dataUser [xvalue asset/meta/tigerdata:project/DataUser $asset]
#     set department [xvalue asset/meta/tigerdata:project/Department $asset]
#     set projectID [xvalue asset/meta/tigerdata:project/ProjectID $asset]
#     set quota [xvalue asset/collection/quota/allocation $asset]
#     puts $id "," $path "," $creatorDomain "," $creatorUser "," $createdOn "," \
#         $quota "," $store "," $projectDirectory "," \"$title\" "," \"$description\" "," \
#         $dataSponsor "," $dataManager ",\"" $dataUser "\",\"" $department "\""," $projectID 
# }
#
#

def parse_multiple(project_metadata, key)
  if project_metadata[key].blank?
    []
  else
    project_metadata[key].split(",").map(&:strip)
  end
end

namespace :import do
    # command line syntax: bundle exec rake metadata:update_pppl_subcommunities\["netid"\]
    desc "import projects from mediaflux csv file"
    task :mediaflux_projects, [:project_file, :test_run] => [:environment] do |_, args|
      project_file = args[:project_file]
      test_run = args[:test_run] || false
      mediaflux_projects = CSV.read(project_file, headers: true)
      mediaflux_projects.each do |project_metadata|
        project_id = project_metadata["projectID"]
        existing_project = Project.where("metadata_json @> ?", JSON.dump(project_id:))
        if existing_project.count > 0
          puts "Skipping project #{project_id}.  There are already #{existing_project.count} version of that project in the system"
        else
          data_user = parse_multiple(project_metadata, "dataUser")
          department_names = parse_multiple(project_metadata,"department")
          departments = department_names.map {|name| Affiliation.find_fuzzy_by_name(name)&.code || name }
          
          storage_size_gb = project_metadata["quota"].downcase.to_f/1000000000.0
          metadata = ProjectMetadata.new_from_hash({
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
          if test_run
            puts metadata.to_json
          else
            project = Project.create!(metadata:, mediaflux_id: project_metadata["asset"])
            puts "Created project for #{project_id}"
          end
        end
      end
    end
  end
