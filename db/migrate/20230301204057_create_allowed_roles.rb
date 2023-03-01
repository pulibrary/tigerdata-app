class CreateAllowedRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :allowed_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
  end
end
