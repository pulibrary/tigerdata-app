# frozen_string_literal: true
# Helper methods for projects
module ProjectHelper
  # For a new project form, pre-populate the data sponsor field with the current user's netid.
  # For an existing project form, pre-populate the data sponsor field with the current value.
  def pre_populate_data_sponsor
    if @project.metadata[:data_sponsor].nil?
      current_user.uid
    else
      @project.metadata[:data_sponsor]
    end
  end
end
