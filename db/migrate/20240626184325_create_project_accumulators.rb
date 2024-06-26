class CreateProjectAccumulators < ActiveRecord::Migration[7.0]
  def change
    create_table :project_accumulators do |t|

      t.timestamps
    end
  end
end
