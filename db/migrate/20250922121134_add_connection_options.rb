class AddConnectionOptions < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :number_of_files, :string, default: "Less than 10,000"
    add_column :requests, :hpc, :string, default: "no"
    add_column :requests, :smb, :string, default: "no"
    add_column :requests, :globus, :string, default: "no"
  end
  def down
    remove_column :requests, :number_of_files, :string, default: "Less than 10,000"
    remove_column :requests, :hpc, :string, default: "no"
    remove_column :requests, :smb, :string, default: "no"
    remove_column :requests, :globus, :string, default: "no"
  end
end