class DropUserJobs < ActiveRecord::Migration[7.0]
  def change
    drop_table(:user_jobs)
  end
end
