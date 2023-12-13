class RemoveCreatedByUser < ActiveRecord::Migration[7.0]
  def change
    remove_column :projects, :created_by_user_id, :integer
  end
end
