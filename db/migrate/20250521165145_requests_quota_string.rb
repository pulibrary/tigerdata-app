class RequestsQuotaString < ActiveRecord::Migration[7.0]
  def up
    rename_column :requests, :quota, :storage_size
    add_column :requests, :storage_unit, :string, default: "GB"
    add_column :requests, :quota, :string, default: "500 GB"
  end

  def down
    remove_column :requests, :quota, :string
    remove_column :requests, :storage_unit, :string
    rename_column :requests, :storage_size, :quota
  end
end
