class CreateProvenanceEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :provenance_events do |t|
      t.string :event_type
      t.string :event_details
      t.string :event_person

      t.timestamps
    end
  end
end
