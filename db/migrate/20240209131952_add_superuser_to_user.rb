class AddSuperuserToUser < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :superuser, :boolean, default: false
    add_column :users, :sysadmin, :boolean, default: false
  end

  def down
    remove_column :users, :superuser, :boolean
    remove_column :users, :sysadmin, :boolean
  end
end
