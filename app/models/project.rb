# frozen_string_literal: true
class Project < ApplicationRecord
  def metadata
    JSON.parse(self.metadata_json || '{}').with_indifferent_access
  end

  def metadata=(metadata)
    self.metadata_json = metadata.to_json
  end
end
