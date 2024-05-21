class AddTrainerToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :trainer, :boolean, default: false
  end
  def down
    remove_column :users, :trainer, :boolean
  end
end
