class AddEventNoteToProvenanceEvent < ActiveRecord::Migration[7.0]
  def change
    add_column :provenance_events, :event_note, :jsonb
  end
end
