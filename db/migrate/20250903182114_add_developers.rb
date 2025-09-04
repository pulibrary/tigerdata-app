class AddDevelopers < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :superuser, :developer
  end
end
