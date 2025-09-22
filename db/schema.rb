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

ActiveRecord::Schema[7.2].define(version: 2025_09_17_175134) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "affiliations", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flipflop_features", force: :cascade do |t|
    t.string "key", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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

  create_table "requests", force: :cascade do |t|
    t.string "request_type"
    t.string "request_title"
    t.string "project_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", default: "draft"
    t.string "data_sponsor"
    t.string "data_manager"
    t.jsonb "departments"
    t.string "description"
    t.string "parent_folder"
    t.string "project_folder"
    t.string "project_id"
    t.float "storage_size"
    t.string "requested_by"
    t.string "storage_unit", default: "GB"
    t.string "quota", default: "500 GB"
    t.jsonb "user_roles"
    t.jsonb "error_message"
    t.string "approved_parent_folder"
    t.string "approved_project_folder"
    t.string "approved_quota"
    t.string "approved_storage_unit"
    t.float "approved_storage_size"
    t.string "project_purpose"
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
    t.boolean "developer", default: false
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
