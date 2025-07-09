# frozen_string_literal: true

class XmlNullBuilder < XmlNodeBuilder
  def build
    document
  end

  def blank?
    true
  end

  # No-op for null builder
  def add_child(_child)
    nil
  end

  def name
    nil
  end

  def initialize(**_options)
    super(document: nil)
  end
end
