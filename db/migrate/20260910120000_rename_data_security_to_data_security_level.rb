class RenameDataSecurityToDataSecurityLevel < ActiveRecord::Migration[8.1]
  def change
    rename_column :new_project_requests, :data_security, :data_security_level
  end
end
