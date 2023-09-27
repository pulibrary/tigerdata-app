class UserAddName < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :given_name, :string
    add_column :users, :family_name, :string
    add_column :users, :display_name, :string
  end

  def down
    remove_column :users, :given_name, :string
    remove_column :users, :family_name, :string
    remove_column :users, :display_name, :string
  end
end
