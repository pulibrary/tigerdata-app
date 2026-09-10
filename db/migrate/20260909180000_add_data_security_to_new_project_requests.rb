class AddDataSecurityToNewProjectRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :new_project_requests, :data_security, :integer
  end
end
