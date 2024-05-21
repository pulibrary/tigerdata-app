class CreateMediafluxTimes < ActiveRecord::Migration[7.0]
  def change
    create_table :mediaflux_times do |t|

      t.timestamps
    end
  end
end
