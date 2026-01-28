# frozen_string_literal: true
class RenameRequestToNewProjectRequest < ActiveRecord::Migration[7.2]
  def change
    rename_table :requests, :new_project_requests
  end
end
