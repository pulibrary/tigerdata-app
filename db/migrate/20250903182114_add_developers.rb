class AddDevelopers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :superuser, :boolean
    add_column :users, :developer, :boolean, default: false
  end
end
