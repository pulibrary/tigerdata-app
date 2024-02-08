class DropRoles < ActiveRecord::Migration[7.0]
  def change
    drop_table(:roles)
  end
end
