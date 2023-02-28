TYPENAMES = {1=>'element',2=>'attribute',3=>'text',4=>'cdata',8=>'comment'}

def xml_to_hash(document)
  # Based on https://stackoverflow.com/a/10144623

  node = document.root
  
  {kind:TYPENAMES[node.node_type],name:node.name}.tap do |h|
    h.merge! nshref:node.namespace.href, nsprefix:node.namespace.prefix if node.namespace
    h.merge! text:node.text
    h.merge! attr:node.attribute_nodes.map(&:to_hash) if node.element?
    h.merge! kids:node.children.map(&:to_hash) if node.element?
  end
end