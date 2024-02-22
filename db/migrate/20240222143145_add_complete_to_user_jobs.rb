class AddCompleteToUserJobs < ActiveRecord::Migration[7.0]
  def up
    add_column :user_jobs, :complete, :boolean, default: false
  end

  def down
    remove_column :user_jobs, :complete, :boolean
  end
end
