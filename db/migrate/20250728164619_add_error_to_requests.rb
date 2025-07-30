class AddErrorToRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :error_message, :jsonb
  end
  def down
    remove_column :requests, :error_message, :jsonb
  end
end
