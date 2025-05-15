#
# Matt Duchknowski script

# Workspace where testing will occur
set root "/princeton/tigerdata/RC/td-testing/md1908"

# The name of the collection asset in root/fixtures that contains the .xml files with fragments to be tested (fixtures)
set doctype "md1908:resource"

# All project nodes located at the root that will receive the metadata during the testing run
# There needs to be only one at this time. In the future, Projects variants may provide additional testing insights
set projects {AProject}


# Helper function to convert XML to Mediaflux shell syntax
proc xtoshell2 {raw} {

    #Native MediaFlux method to convert XML --> Shell
	set shellsyntax [xtoshell $raw]

	# Step 1: replace quote colon with quote space colon
	set resolved [string map {"\":" "\" :"} $shellsyntax]

	# Step 2: Remove the namespace attributes metadata
	set dns [string range [lindex [split [string trim $resolved " "] " "] 0] 1 end]
	set body [join [lrange [split [string trim $resolved " "] "<"] 1 end] "<"]
	set meta ":$dns <$body"

	#Step 3: Clean html escape codes
	set output [string map -nocase { "&lt;" "<" "&gt;" ">" "&#34;" "\"" } $meta]

	return $output
}


set ReturnMsg "\n\n"

foreach proj $projects {

    append ReturnMsg "Project : $proj\n"
    append ReturnMsg "Path    : $root/$proj\n\n"

    #Get all fixtures
    set ids [xvalues id [asset.query :where "asset in collection or subcollection of '$root/fixtures/$doctype' maximum depth 1"]]


    foreach id $ids {

        asset.meta.node.remove :id path=$root/$proj :xpath $doctype

        # Get fixture
        set asset [asset.get :id $id]
        set name [xvalue asset/name $asset]
        append ReturnMsg "Testing Fixture : $name (id=$id)\n"

        # Read  XML file (as asset) to raw metadata string
        set rawmetadata [xelements asset/content/xml/$doctype [asset.get :content-as-xml true :id path=$root/fixtures/$doctype/$name]]

        # Convert XML to Mediaflux shell syntax
        set metadata [xtoshell2 $rawmetadata]

        # Execute syntax via template substitution
        eval [subst -nocommands {asset.set :id path=$root/$proj :allow-invalid-meta true :meta < $metadata >}]

        set rawmetadata [xelements asset/meta/$doctype [asset.get :id path=$root/$proj ]]

        if {[string equal $rawmetadata "<result></result>"]} {
            append ReturnMsg "Fixture Received : False\n"
        } else {
            append ReturnMsg "Fixture Received : True\n"
        }


        set invalids [xelements invalid [asset.meta.validate :id path=$root/$proj :allow-incomplete false]]
        if {[string equal $invalids ""]} {
            append ReturnMsg "Invalid : NONE  \n  $invalids \n"
        } else {
            append ReturnMsg "Invalid : FOUND \n  $invalids \n"
        }

        append ReturnMsg "\n"

        asset.meta.node.remove :id path=$root/$proj :xpath $doctype

    }


}

return $ReturnMsg
