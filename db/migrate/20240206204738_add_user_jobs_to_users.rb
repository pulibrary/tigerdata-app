class AddUserJobsToUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :user_jobs do |t|
      t.belongs_to :user
      t.string :job_id
      t.string :project_title
      t.timestamps
      t.foreign_key :users, null: false
    end
  end
end
