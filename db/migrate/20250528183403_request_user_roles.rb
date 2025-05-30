class RequestUserRoles < ActiveRecord::Migration[7.0]
  def up
    add_column :requests, :user_roles, :jsonb
  end

  def down
    remove_column :requests, :user_roles, :jsonb
  end
end
