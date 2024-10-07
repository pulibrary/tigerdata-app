# DESCRIPTION:
#
# Returns a list of files (assets) for a given path.
#
# This script uses iterators to handle cases where there are many files
# in the given path. Therefore the first time you call it you give it a
# `path` and the script will give you back an interator. Call the script
# again with the `iterator` to start iterating over the list of files.
#
# Call it as many times until the return includes `iterated complete="true"`
#
#
# RUNNING THE SCRIPT OUTSIDE OF MEDIAFLUX:
#
#   script.execute :in file:/Users/correah/src/mediaflux/fileList.tcl :arg -name path /path/to/collection
#   script.execute :in file:/Users/correah/src/mediaflux/fileList.tcl :arg -name iterator $iterator
#
# INSTALLING THE SCRIPT IN MEDIAFLUX...
#
#   asset.namespace.create :namespace /system/scripts
#   asset.create :namespace /system/scripts :name fileList.tcl :in file:/Users/correah/src/mediaflux/fileList.tcl
#   asset.set.executable :id path=/system/scripts/fileList.tcl :executable true
#
# ...AND RUNNING IT FROM WITHIN MEDIAFLUX:
#
#   asset.script.execute :id path=/system/scripts/fileList.tcl :arg -name path /path/to/collection
#   asset.script.execute :id path=/system/scripts/fileList.tcl :arg -name iterator $iterator
#
# TO REPLACE THE SCRIPT IN MEDIAFLUX YOU HAVE TO DESTROY IT AND RECREATE IT:
#
#   asset.destroy :id path=/system/scripts/fileList.tcl
#

if { [info exists "path"] } \
{
  # Initial query to get the iterator
  server.log :app "filelist" :event info :msg "File list for ${path}"
  asset.query :collection path=$path :action get-name :as iterator
} \
else \
{
  if { [info exists "iterator"] } \
  {
    # Iterate over the results
    server.log :app "filelist" :event info :msg "Iterator for ${iterator}"
    asset.query.iterate :id ${iterator}
  } \
  else {
    server.log :app "filelist" :event error :msg "You must specify a path or an iterator"
  }
}

