# frozen_string_literal: true
class ProjectPurpose
  attr_accessor :id, :label

  def initialize(id, label)
    @id = id
    @label = label
  end

  def self.all
    research = ProjectPurpose.new("research", "Research")
    admin = ProjectPurpose.new("administrative", "Administrative")
    teaching = ProjectPurpose.new("teaching", "Teaching")
    [research, admin, teaching]
  end

  # Returns the label for a given purpose id
  def self.label_for(id)
    all.each do |purpose|
      return purpose.label if purpose.id == id
    end
    id
  end
end
