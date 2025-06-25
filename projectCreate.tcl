# DESCRIPTION:
#
# Creates a new TigerData project
#
# NOTE:
#   This script should eventually be part of tigerdata-config, but for now I am keeping
#   in this repo to help me test the process end to end.
#
# RUNNING THE SCRIPT OUTSIDE OF MEDIAFLUX:
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/projectCreate.tcl :arg -name doi 10.123/456
#
# INSTALLING THE SCRIPT IN MEDIAFLUX...
#
#   asset.namespace.create :namespace /system/scripts
#   asset.create :namespace /system/scripts :name projectCreate.tcl :in file:/Users/correah/src/tigerdata-app/projectCreate.tcl
#   asset.set.executable :id path=/system/scripts/projectCreate.tcl :executable true
#
# ...AND RUNNING IT FROM WITHIN MEDIAFLUX:
#
#   asset.script.execute :id path=/system/scripts/projectCreate.tcl :arg -name doi 10.123/456
#
# TO REPLACE THE SCRIPT IN MEDIAFLUX YOU HAVE TO DESTROY IT AND RECREATE IT:
#
#   asset.destroy :id path=/system/scripts/projectCreate.tcl
#

if { [info exists "doi"] } \
{
  server.log :app "projectCreate" :event info :msg "Creating project for DOI ${doi}"

  # Project values
  set projectDirectory "test-minimal-9"
  set projectDescription "This is just an example description."
  set projectDOI "10.34770/az09-0001"
  set projectTitle "Test Project 1"
  set schemaVersion "v0.8"

  # Mediaflux paths
  set ns "NS"
  set rootCollection "/td-demo-001/dev/tigerdata"
  set rootNamespace "/td-demo-001/dev/tigerdataNS"
  set projectCollection $rootCollection/$projectDirectory
  set projectNamespace $rootNamespace/$projectDirectory$ns

  # Create a namespace for our test project
  set createNS [xvalue exists [asset.namespace.exists :namespace $projectNamespace]]
  if { "$createNS" != "true" } \
  {
      asset.namespace.create :namespace $projectNamespace
  }



  # ==============================================
  #
  # TODO: Update to create the project with the existing tigerdata:project schema
  #
  # ==============================================

  # Create the collection for the test project and set the value for the TigerData schema
  asset.create \
      :pid path=$rootCollection \
      :namespace $projectNamespace \
      :name $projectDirectory \
      :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true \
      :type "application/arc-asset-collection" \
      :meta < \
          :tigerdataX:resourceDoc < \
              :resource -resourceClass "Project" -resourceID $projectDOI -resourceIDType "DOI" < \
                  :title -lang "en" $projectTitle \
                  :description -lang "en" -inherited false -discoverable true -trackingLevel "ResourceRecord" $projectDescription \
                  :projectID -projectIDType "DOI" -inherited true -discoverable true -trackingLevel "ResourceRecord" $projectDOI \
                  :projectDirectory -inherited false -discoverable false -trackingLevel "InternalUseOnly" -approved true \
                  < \
                      :projectDirectoryPath -protocol "NFS" $projectDirectory \
                      :requestedValue -protocol "NFS" $projectDirectory \
                      :approvedValue -protocol "NFS" $projectDirectory \
                  > \
                  :dataSponsor -userID "mjc12" -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                  :dataManager -userID "mjc12" -userIDType "NetID" -discoverable true -inherited true -trackingLevel "ResourceRecord" \
                  :departments -discoverable true -trackingLevel "ResourceRecord" < \
                      :department -departmentCode RDSS -inherited false "Research Data and Scholarly Services" \
                  > \
                  :projectProvenance < \
                      :schemaVersion $schemaVersion \
                  > \
              > \
          > \
      >


} \
else \
{
  server.log :app "projectCreate" :event error :msg "You must provide a DOI"
}
