# frozen_string_literal: true
require "yaml"

# frozen_string_literal: true
TYPENAMES = { 1 => "element", 2 => "attribute", 3 => "text", 4 => "cdata", 8 => "comment" }.freeze

def xml_node_to_hash(node)
  # Based on https://stackoverflow.com/a/10144623
  {}.tap do |h|
    h[:name] = node.name
    node_type_name = TYPENAMES[node.node_type]
    if node_type_name != "element"
      h[:name] += " (#{node_type_name})"
    end
    if node.namespace
      h[:nshref] = node.namespace.href
      h[:nsprefix] = node.namespace.prefix
    end
    h[:text] = node.text unless node.text.empty?
    h[:attr] = node.attribute_nodes.map { |attr_node| xml_node_to_hash(attr_node) } if node.element? && !node.attribute_nodes.empty?
    h.merge! subelements: node.children.map { |child_node| xml_node_to_hash(child_node) } if node.element? && !node.children.empty?
  end
end

def xml_doc_to_hash(document)
  xml_node_to_hash(document.root)
end

def xml_doc_to_html(document)
  as_hash = xml_doc_to_hash(document)
  as_yaml = YAML.dump(as_hash).gsub(/\A---\n/, "")
  "<pre>#{CGI.escapeHTML(as_yaml)}</pre>"
end
