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

namespace :import do
  # command line syntax: bundle exec rake metadata:update_pppl_subcommunities\["netid"\]
  desc "import projects from mediaflux csv file"
  task :mediaflux_projects, [:project_file, :test_run] => [:environment] do |_, args|
    project_file = args[:project_file]
    test_run = args[:test_run] || false
    importer = ProjectImport.new(File.new(project_file), test_run: test_run)
    output = importer.run
    output.each { |line| puts line }
  end
end
