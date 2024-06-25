# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_06_25_182512) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "projects", force: :cascade do |t|
    t.integer "mediaflux_id"
    t.jsonb "metadata_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provenance_events", force: :cascade do |t|
    t.string "event_type"
    t.string "event_details"
    t.string "event_person"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "project_id"
    t.jsonb "event_note"
    t.index ["project_id"], name: "index_project_id"
  end

  create_table "user_requests", force: :cascade do |t|
    t.integer "user_id"
    t.integer "project_id"
    t.uuid "job_id"
    t.datetime "completion_time"
    t.string "state"
    t.string "type"
    t.jsonb "request_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "given_name"
    t.string "family_name"
    t.string "display_name"
    t.boolean "eligible_sponsor", default: false
    t.boolean "eligible_manager", default: false
    t.boolean "superuser", default: false
    t.boolean "sysadmin", default: false
    t.boolean "trainer", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_users_on_uid"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

end
