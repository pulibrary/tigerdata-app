# Execute this script to populate a MediaFlux server with some sample data:
# - a metadata schema
# - a namespace
# - a collection asset within the namespace
# - set the collection asset with some values for the fields defined in the metadata schema
#
# You can run it from within Aterm with a command as follows:
#
# script.execute :in file://full/path/to/tiger-data-app/docs/sandbox_data.md

# ------------------------------------------------------
# YOU CAN SET THESE VALUES TO YOUR LIKING
# (The value used for demo_content_file should point to a file that exists on your machine
# /etc/protocols is a good bet but adust if necessary)
set demo_schema sandbox_meta12
set demo_ns sandbox_ns12
set demo_project rdss_project12
set demo_content_file /etc/protocols
# ------------------------------------------------------


# Fixes the display bug in the Desktop
actor.grant :type user :name system:manager :role -type role desktop-experimental


# Defines a metadata namespace with one document type for "project" data
asset.doc.namespace.create :namespace $demo_schema :description "the metadata definition for our sandbox"

asset.doc.type.update :create true :description "sandbox metadata" :type $demo_schema:project :definition < :element -name name -type string :element -name sponsor -type string :element -name max_gb -type integer :element -name created_on -type date >


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
asset.set :id path=/$demo_ns/$demo_project :meta < :$demo_schema:project < :name "RDSS test project" :sponsor "Library" :max_gb 100 :created_on "31-AUG-2023" > >

# eof
