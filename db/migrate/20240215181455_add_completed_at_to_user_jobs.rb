class AddCompletedAtToUserJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :user_jobs, :completed_at, :datetime
  end
end
