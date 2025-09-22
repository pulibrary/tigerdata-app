class AddProjectPurposeToRequest < ActiveRecord::Migration[7.2]
  def change
    add_column :requests, :project_purpose, :string
  end
end
