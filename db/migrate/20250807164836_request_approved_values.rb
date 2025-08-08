class RequestApprovedValues < ActiveRecord::Migration[7.0]
  def up
    add_column :requests, :approved_parent_folder, :string
    add_column :requests, :approved_project_folder, :string
    add_column :requests, :approved_quota, :string
    add_column :requests, :approved_storage_unit, :string
    add_column :requests, :approved_storage_size, :float
  end
end
