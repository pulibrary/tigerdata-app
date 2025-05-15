class RequestProdFields < ActiveRecord::Migration[7.0]
  def up
    add_column :requests, :state, :string, default: "draft"
    add_column :requests, :data_sponsor, :string
    add_column :requests, :data_manager, :string
    add_column :requests, :departments, :string
    add_column :requests, :description, :string
    add_column :requests, :parent_folder, :string
    add_column :requests, :project_folder, :string
    add_column :requests, :project_id, :string
    add_column :requests, :quota, :float
    add_column :requests, :requested_by, :string
  end
  def down
    remove_column :requests, :state, :string
    remove_column :requests, :data_sponsor, :string
    remove_column :requests, :data_manager, :string
    remove_column :requests, :departments, :string
    remove_column :requests, :description, :string
    remove_column :requests, :parent_folder, :string
    remove_column :requests, :project_folder, :string
    remove_column :requests, :project_id, :string
    remove_column :requests, :quota, :float
    remove_column :requests, :requested_by, :string
  end
end
