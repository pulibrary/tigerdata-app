
# add_approval_metadata
#
# Sends an command similar to the command below by taking the current state of the asset and updating the StorageCapacity and Submission elements with data passed in on the command line
#
# service/execute :service -name "asset.set" < :id "1574" :meta -action "replace" < :tigerdata:project -xmlns:tigerdata "tigerdata" < :ProjectDirectory "/td-demo-001/tigerdataNS/test-05-30-24" :Title "testing approval" \
#    :Description "I want to test the approval updates" :Status "approved" :DataSponsor "cac9" :DataManager "mjc12" :Department "RDSS" :DataUser -ReadOnly "true" "la15" :DataUser "woongkim" :CreatedOn "30-MAY-2024 09:11:09" \
#    :CreatedBy "cac9" :ProjectID "10.34770/tbd" :StorageCapacity < :Size -Requested "500" -Approved "1" "1" :Unit -Requested "GB" -Approved "TB" "TB" > :Performance -Requested "Standard" -Approved "Standard" "Standard" \
#    :Submission < :RequestedBy "cac9" :RequestDateTime "30-MAY-2024 13:11:09" :ApprovedBy "cac9" :ApprovalDateTime "30-MAY-2024 13:12:44" \
#    :EventlNote < :NoteDateTime "30-MAY-2024 13:12:44" :NoteBy "cac9" :EventType "Quota" :Message "A note" > > :ProjectPurpose "Research" :SchemaVersion "0.6.1" > > >
#
# Usage:
#
#   script.execute :in add_approval_metadata.tcl :arg -name id 1574 :arg -name storage_capacity_size 40 :arg -name storage_capacity_unit TB :arg -name approved_by cac9 :arg -name approved_date "03-June-2024 07:45:00" :arg -name event_note "This is a note" :arg -name event_type "Quota"
#
# Steps to upload as an asset script:
#   1. Make sure the scripts namespace exists
#      service.execute :service -name "asset.namespace.create" < :namespace -all "true" "/system/scripts" >
#   2. Upload the script into the namespace
#      asset.create :namespace /system/scripts :name add_approval_metadata.tcl :in add_approval_metadata.tcl
#   3. Mark the script as executable
#      asset.set.executable :id path=/system/scripts/add_approval_metadata.tcl :executable true
#   4. Run the asset script as needed
#      asset.script.execute :sid path=/system/scripts/add_approval_metadata.tcl :arg -name id 1574 :arg -name storage_capacity_size 40 :arg -name storage_capacity_unit TB :arg -name approved_by cac9 :arg -name approved_date "03-June-2024 07:45:00" :arg -name event_note "This is a note2" :arg -name event_type "Quota2" 
#   5.  Any updates to the script can be done with 
#      asset.set :id path=/system/scripts/add_approval_metadata.tcl :in add_approval_metadata.tcl
#


set log_name "provenance-update"
server.log :app ${log_name} :event info :msg "Updating the provenance for ${id}"
set assetxml [ asset.get :id $id ]
set storage_capacity_size_requested [xvalue asset/meta/tigerdata:project/StorageCapacity/Size/@Requested $assetxml]
set storage_capacity_unit_requested [xvalue asset/meta/tigerdata:project/StorageCapacity/Unit/@Requested $assetxml]
set submission_requested_by [xvalue asset/meta/tigerdata:project/Submission/RequestedBy $assetxml]
set submission_requested_date [xvalue asset/meta/tigerdata:project/Submission/RequestDateTime $assetxml]
set meta_xml [ xelement asset/meta/tigerdata:project $assetxml]
set old_doc [xtoshell $meta_xml]
if { $storage_capacity_size_requested == ""} {
  set new_storage_element ":StorageCapacity < :Size -Requested \"500\" -Approved \"${storage_capacity_size}\" \"${storage_capacity_size}\" :Unit -Requested \"GB\" -Approved \"${storage_capacity_unit}\" \"${storage_capacity_unit}\" >"
} else {
  set new_storage_element ":StorageCapacity < :Size -Requested \"${storage_capacity_size_requested}\" -Approved \"${storage_capacity_size}\" \"${storage_capacity_size}\" :Unit -Requested \"${storage_capacity_unit_requested}\" -Approved \"${storage_capacity_unit}\" \"${storage_capacity_unit}\" >"
}
set old_storage_element [xtoshell [xelement tigerdata:project/StorageCapacity $meta_xml]]
set new_submission_element ":Submission < :RequestedBy \"${submission_requested_by}\" :RequestDateTime \"${submission_requested_date}\" :ApprovedBy \"${approved_by}\" :ApprovalDateTime \"${approved_date}\" :EventlNote < :NoteDateTime \"${approved_date}\" :NoteBy \"${approved_by}\" :EventType \"${event_type}\" :Message \"${event_note}\" > >"
set old_submission_element [xtoshell [xelement tigerdata:project/Submission $meta_xml]]

set newProjectXml [string map [list ${old_storage_element} ${new_storage_element} ${old_submission_element} ${new_submission_element}] $old_doc]
set withSpace [string map [list {":} {" :} {>:} {> :}] $newProjectXml]
set updateScript ":service -name \"asset.set\" < :id \"${id}\" :meta -action \"replace\" < $withSpace > >"
puts " ------------ "
set output [service.execute $updateScript]
puts $output
server.log :app ${log_name} :event info :msg "Updated the provenance for ${id}"