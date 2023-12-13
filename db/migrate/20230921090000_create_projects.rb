class CreateProjects < ActiveRecord::Migration[7.0]
    def change
      create_table :projects do |t|
        t.integer :mediaflux_id
        t.jsonb :metadata_json
        t.timestamps
      end
    end
  end
