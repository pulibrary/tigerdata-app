# frozen_string_literal: true

class UserJob < ApplicationRecord
  def title
    "File Inventory for \"#{project_title}\""
  end

  def description
    "Requested #{created_at}"
  end
end
