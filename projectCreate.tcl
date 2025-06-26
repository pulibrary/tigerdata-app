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
#   script.execute :in file:/Users/correah/src/tigerdata-app/projectCreate.tcl :arg -name doi 10.123/456 :arg -name directory test-123 :arg -name title "hello world"
#
# INSTALLING THE SCRIPT IN MEDIAFLUX...
#
#   asset.namespace.create :namespace /system/scripts
#   asset.create :namespace /system/scripts :name projectCreate.tcl :in file:/Users/correah/src/tigerdata-app/projectCreate.tcl
#   asset.set.executable :id path=/system/scripts/projectCreate.tcl :executable true
#
# ...AND RUNNING IT FROM WITHIN MEDIAFLUX:
#
#   asset.script.execute :id path=/system/scripts/projectCreate.tcl :arg -name doi 10.123/456 :arg -name directory test-308 :arg -name title "hello world"
#
# TO REPLACE THE SCRIPT IN MEDIAFLUX YOU HAVE TO DESTROY IT AND RECREATE IT:
#
#   asset.destroy :id path=/system/scripts/projectCreate.tcl
#

if { [info exists "doi"] && [info exists "directory"] && [info exists "title"] } \
{
  server.log :app "projectCreate" :event info :msg "Creating project for DOI ${doi}"

  # Hard-coded project values for now
  # TODO: Make these values arguments to the TCL script
  set schemaVersion "v0.8"
  set dataSponsor "hc8719"
  set department "LIB-RDSS"

  # Mediaflux paths
  set ns "NS"
  set rootCollection "/td-demo-001/dev/tigerdata"
  set rootNamespace "/td-demo-001/dev/tigerdataNS"
  set projectCollection $rootCollection/$directory
  set projectNamespace $rootNamespace/$directory$ns

  # Create a namespace for our test project
  set createNS [xvalue exists [asset.namespace.exists :namespace $projectNamespace]]
  if { "$createNS" != "true" } \
  {
      asset.namespace.create :namespace $projectNamespace
  }

  # Create the collection for the test project and set the value for the TigerData schema
  asset.create \
      :pid path=$rootCollection \
      :namespace $projectNamespace \
      :name $directory \
      :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true \
      :type "application/arc-asset-collection" \
      :meta < \
          :tigerdata:project < \
            :ProjectDirectory $directory \
            :Title $title \
            :Status "status" \
            :DataSponsor $dataSponsor \
            :DataManager $dataSponsor \
            :Department $department \
            :CreatedOn "NOW" \
            :CreatedBy $dataSponsor \
            :ProjectID $doi \
            :StorageCapacity < \
              :Size -Requested "123" -Approved "123" 123 \
              :Unit -Requested "KB" -Approved "KB" "KB" \
            > \
            :Performance -Requested "Standard" -Approved "Standard" "Standard" \
            :ProjectPurpose "testing" \
            :Submission < \
              :RequestedBy $dataSponsor \
              :RequestDateTime "NOW" \
            > \
            :SchemaVersion $schemaVersion \
          > \
      >
} \
else \
{
  server.log :app "projectCreate" :event error :msg "You must provide: doi, directory, and title"
}
