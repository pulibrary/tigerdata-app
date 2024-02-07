class UserAddRoles < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :eligible_sponsor, :boolean, default: false
    add_column :users, :eligible_manager, :boolean, default: false
  end

  def down
    remove_column :users, :eligible_sponsor, :boolean
    remove_column :users, :eligible_manager, :boolean
  end
end
