# Execute this script to populate a MediaFlux server with some sample data:
# - a metadata schema
# - a namespace
# - a collection asset within the namespace
# - set the collection asset with some values for the fields defined in the metadata schema
#
# You can run it from within Local Aterm (not a Web Aterm) with a command as follows:
#
# script.execute :in file://full/path/to/tigerdata-app/docs/sandbox_data.md
# 
# In the same aterm, to see the resultant collection with metadata run:
# asset.collection.list :namespace /tigerdata_ns02 :assets true

# ------------------------------------------------------
# YOU CAN SET THESE VALUES TO YOUR LIKING
# (The value used for demo_content_file should point to a file that exists on your machine
# /etc/protocols is a good bet but adust if necessary)
set demo_schema tigerdata_meta02
set demo_ns tigerdata_ns02
set demo_project rdss_project02
set demo_content_file /etc/protocols
# ------------------------------------------------------


# Fixes the display bug in the Desktop
actor.grant :type user :name system:manager :role -type role desktop-experimental


# Defines a metadata namespace with one document type for "project" data
asset.doc.namespace.create :namespace $demo_schema :description "TigerData metadata schema"

asset.doc.type.update :create true :description "Project metadata" :type $demo_schema:project :definition < \
    :element -name id            -type string -index true -min-occurs 1 -max-occurs 1 -label "The unique identifier for the project" \
    :element -name title         -type string             -min-occurs 1 -max-occurs 1 -label "A plain-language title for the project" \
    :element -name description   -type string             -min-occurs 1 -max-occurs 1 -label "A brief description of the project" \
    :element -name data_sponsor  -type string -index true -min-occurs 1 -max-occurs 1 -label "The person who takes primary responsibility for the project" \
    :element -name data_manager  -type string -index true -min-occurs 1 -max-occurs 1 -label "The person who manages the day-to-day activities for the project" \
    :element -name data_users_rw -type string -index true -min-occurs 0               -label "A person who has read and write access privileges to the project" \
    :element -name data_users_ro -type string -index true -min-occurs 0               -label "A person who has read-only access privileges to the project" \
    :element -name departments   -type string -index true -min-occurs 1               -label "The primary Princeton University department(s) affiliated with the project" \
    :element -name created_on    -type date               -min-occurs 1 -max-occurs 1 -label "Timestamp project was created" \
    :element -name created_by    -type string             -min-occurs 1 -max-occurs 1 -label "User that created the project" >

# Creates namespace and collection asset inside the namespace
asset.namespace.create :namespace /$demo_ns
asset.create :namespace /$demo_ns :name $demo_project :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true


# Adds a new few asset to the collection asset
asset.create :pid path=/$demo_ns/$demo_project :name file01.txt
asset.create :pid path=/$demo_ns/$demo_project :name file02.txt
asset.create :pid path=/$demo_ns/$demo_project :name file03.txt
asset.create :pid path=/$demo_ns/$demo_project :name file04.txt


# Sets the content for one of those assets
asset.set :id path=/$demo_ns/$demo_project/file01.txt :in file:$demo_content_file


# Sets the metadata of our demo project using the fields defined in our metadata namespace
asset.set :id path=/$demo_ns/$demo_project :meta < \
    :$demo_schema:project < \
        :id "09az-0001" \
        :title "Our first test project" \
        :description "This is a test project" \
        :data_sponsor "mjc12" \
        :data_manager "kl37" \
        :data_users_rw "hc8719" \
        :data_users_rw "cac9" \
        :data_users_ro "bs3097" \
        :data_users_ro "jrg5" \
        :departments "RDSS" \
        :departments "HPC" \
        :created_on "31-AUG-2023" \
        :created_by "hc8719" > >

# eof
