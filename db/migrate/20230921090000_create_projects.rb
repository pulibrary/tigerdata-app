class CreateProjects < ActiveRecord::Migration[7.0]
    def change
      create_table :projects do |t|
        t.integer :created_by_user_id
        t.integer :mediaflux_id
        t.jsonb :metadata_json
        t.timestamps
      end
    end
  end
