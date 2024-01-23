class AddProvenanceEventAssociationToProject < ActiveRecord::Migration[7.0]
  def change
    add_column :provenance_events, :project_id, :integer
    add_index "provenance_events", ["project_id"], :name => "index_project_id"
  end
end
