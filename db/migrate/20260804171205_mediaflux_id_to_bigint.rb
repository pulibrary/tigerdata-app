class MediafluxIdToBigint < ActiveRecord::Migration[8.1]
  def change
    change_column :projects, :mediaflux_id, :bigint
  end
end
