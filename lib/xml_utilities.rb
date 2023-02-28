# frozen_string_literal: true
TYPENAMES = { 1 => "element", 2 => "attribute", 3 => "text", 4 => "cdata", 8 => "comment" }.freeze

def xml_to_hash(document)
  # Based on https://stackoverflow.com/a/10144623

  node = document.root

  { kind: TYPENAMES[node.node_type], name: node.name }.tap do |h|
    if node.namespace
      h[:nshref] = node.namespace.href
      h[:nsprefix] = node.namespace.prefix
    end
    h[:text] = node.text unless node.text.empty?
    h[:attr] = node.attribute_nodes.map(&:to_hash) if node.element? && !node.attribute_nodes.empty?
    h.merge! kids: node.children.map(&:to_hash) if node.element? && !node.children.empty?
  end
end
