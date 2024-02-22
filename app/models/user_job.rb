# frozen_string_literal: true

class UserJob < ApplicationRecord
  def title
    "File Inventory for \"#{project_title}\""
  end

  def created_datestamp
    localized = created_at.localtime
    localized.strftime("%Y-%m-%dT%H:%M:%S%:z")
  end

  def updated_datestamp
    localized = updated_at.localtime
    localized.strftime("%Y-%m-%dT%H:%M:%S%:z")
  end

  def description
    if complete
      "Completed #{updated_datestamp}"
    else
      "Requested #{created_datestamp}"
    end
  end
end
