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

ActiveRecord::Schema[8.1].define(version: 2026_06_03_182404) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "affiliations", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flipflop_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inventory_requests", force: :cascade do |t|
    t.datetime "completion_time"
    t.datetime "created_at", null: false
    t.uuid "job_id"
    t.integer "project_id"
    t.jsonb "request_details"
    t.string "state"
    t.string "type"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "new_project_requests", force: :cascade do |t|
    t.string "approved_parent_folder"
    t.string "approved_project_folder"
    t.string "approved_quota"
    t.float "approved_storage_size"
    t.string "approved_storage_unit"
    t.datetime "created_at", null: false
    t.string "data_manager"
    t.string "data_sponsor"
    t.jsonb "departments"
    t.string "description"
    t.jsonb "error_message"
    t.string "globus", default: "no"
    t.string "hpc", default: "no"
    t.string "number_of_files", default: "Less than 10,000"
    t.string "parent_folder"
    t.string "project_folder"
    t.string "project_id"
    t.string "project_purpose"
    t.string "project_title"
    t.string "quota", default: "500 GB"
    t.string "request_title"
    t.string "request_type"
    t.string "requested_by"
    t.string "smb", default: "no"
    t.string "state", default: "draft"
    t.float "storage_size"
    t.string "storage_unit", default: "GB"
    t.datetime "updated_at", null: false
    t.jsonb "user_roles"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "mediaflux_id"
    t.jsonb "metadata_json"
    t.datetime "updated_at", null: false
  end

  create_table "provenance_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_details"
    t.jsonb "event_note"
    t.string "event_person"
    t.string "event_type"
    t.integer "project_id"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "developer", default: false
    t.string "display_name"
    t.boolean "eligible_manager", default: false
    t.boolean "eligible_sponsor", default: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "family_name"
    t.string "given_name"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.boolean "sysadmin", default: false
    t.boolean "trainer", default: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_users_on_uid"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "user_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end
end
