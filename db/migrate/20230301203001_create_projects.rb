class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.jsonb :data

      t.timestamps
    end
  end
end
