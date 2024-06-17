class CreateUserRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :user_requests do |t|
      t.integer :user_id
      t.integer :project_id
      t.integer :job_id
      t.datetime :completion_time
      t.string :state
      t.string :type
      t.jsonb :request_details

      t.timestamps
    end
  end
end
