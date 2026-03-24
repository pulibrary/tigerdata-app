# frozen_string_literal: true

# Represents a project purpose with id and label.
class ProjectPurpose
  attr_accessor :id, :label

  # Initializes a new ProjectPurpose instance.
  # @param [String] id the purpose id.
  # @param [String] label the purpose label.
  def initialize(id, label)
    @id = id
    @label = label
  end

  # Returns all possible project purposes.
  # @return [Array<ProjectPurpose>] the list of purposes.
  def self.all
    research = ProjectPurpose.new("research", "Research")
    admin = ProjectPurpose.new("administrative", "Administrative")
    teaching = ProjectPurpose.new("teaching", "Teaching")
    [research, admin, teaching]
  end

  # Returns the label for a given purpose id.
  # @param [String] id the purpose id.
  # @return [String] the label or id if not found.
  def self.label_for(id)
    all.each do |purpose|
      return purpose.label if purpose.id == id
    end
    id
  end
end
