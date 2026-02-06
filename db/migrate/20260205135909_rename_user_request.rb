class RenameUserRequest < ActiveRecord::Migration[7.2]
  def change
    rename_table :user_requests, :inventory_requests
  end
end
