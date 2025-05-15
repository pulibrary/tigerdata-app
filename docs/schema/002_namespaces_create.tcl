# Creates the root namespaces for our projects and the root collection
#
# script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema/002_namespaces_create.tcl
#
# This is hardcoded to /td-demo-001/dev/tigerdata and /td-demo-001/dev/tigerdataNS
#

# Create the /tigerdata namespace
set createRoot1 [xvalue exists [asset.namespace.exists :namespace /td-demo-001]]
if { "$createRoot1" != "true" } \
{
    puts "Creating /td-demo-001"
    asset.namespace.create :namespace /td-demo-001
}

# Create the /tigerdata/dev namespace
set createRoot2 [xvalue exists [asset.namespace.exists :namespace /td-demo-001/dev]]
if { "$createRoot2" != "true" } \
{
    puts "Creating /td-demo-001/dev"
    asset.namespace.create :namespace /td-demo-001/dev
}

# Create the /tigerdata/dev/tigerdata root collection
set createRoot3 [xvalue exists [asset.exists :id path=/td-demo-001/dev/tigerdata]]
if { "$createRoot3" != "true" } \
{
    asset.create \
         :namespace /td-demo-001/dev \
         :name tigerdata \
         :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true \
         :type "application/arc-asset-collection"
}

# Create the /tigerdata/dev/tigerdataNS namespace
set createRoot4 [xvalue exists [asset.namespace.exists :namespace /td-demo-001/dev/tigerdataNS]]
if { "$createRoot2" != "true" } \
{
    puts "Creating /td-demo-001/dev"
    asset.namespace.create :namespace /td-demo-001/dev/tigerdataNS
}
