class AddDeveloperToUser < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :developer, :boolean, default: false
    add_column :users, :sysadmin, :boolean, default: false
  end

  def down
    remove_column :users, :developer, :boolean
    remove_column :users, :sysadmin, :boolean
  end
end
