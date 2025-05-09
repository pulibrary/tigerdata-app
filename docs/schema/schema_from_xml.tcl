# Steps to create the metadata schema from an initial XML file
# and then export it as a TCL script for tweaking and re-creation.


# WARNING: You CANNOT run this file from Aterm via
#
#   script.execute :in file:/Users/correah/src/tigerdata-app/docs/schema_from_xml.tcl
#
# because for some reason ATerm cannot find the initialXML file.


# Create the namespace for the schema
asset.doc.namespace.update :create true :namespace tigerdataX

# Create the document type for the schema
# from the data in the initialXML file
asset.doc.type.create.from.xml :in file:///Users/correah/src/tigerdata-app/docs/schema/small_schema.xml :namespace tigerdataX :include-root true

# Destroy the resource is already there
#   asset.doc.type.destroy :type tigerdataX:resource

# Create the TCL script from the schema definition in Mediaflux
# Notice that it includes all the definitions under tigerdataX
# I have not found a way to filter by only the "resource" definition
# that we created from the initial XML.
asset.doc.type.script.create :namespace tigerdataX :out file:///Users/correah/src/tigerdata-app/docs/schema/small_schema.tcl


script.execute :in file:/Users/correah/src/tigerdata-app/docs/small_schema.tcl