class AddConnectionOptions < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :number_files, :string, default: "unknown"
    add_column :requests, :hpc, :string, default: "no"
    add_column :requests, :network_share, :string, default: "no"
    add_column :requests, :globus, :string, default: "no"
  end
  def down
    remove_column :requests, :number_files, :string, default: "unknown"
    remove_column :requests, :hpc, :string, default: "no"
    remove_column :requests, :network_share, :string, default: "no"
    remove_column :requests, :globus, :string, default: "no"
  end
end
