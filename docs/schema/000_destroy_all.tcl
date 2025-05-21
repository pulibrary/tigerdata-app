# Use this to reset your development environment
# (the values references on this script do not exist in production.)
#
# Deletes the /td-demo-001 namespace and everything underneath
# as well as the tigerdataX document namespace definition
asset.namespace.destroy :namespace /td-demo-001
asset.doc.namespace.destroy :namespace tigerdataX