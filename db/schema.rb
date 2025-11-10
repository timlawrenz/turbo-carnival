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

ActiveRecord::Schema[8.0].define(version: 2025_11_10_215403) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "comfyui_jobs", force: :cascade do |t|
    t.bigint "image_candidate_id"
    t.bigint "pipeline_run_id", null: false
    t.bigint "pipeline_step_id", null: false
    t.string "comfyui_job_id"
    t.string "status", default: "pending", null: false
    t.jsonb "job_payload", null: false
    t.jsonb "result_metadata"
    t.text "error_message"
    t.integer "retry_count", default: 0, null: false
    t.datetime "submitted_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_candidate_id"
    t.index ["comfyui_job_id"], name: "index_comfyui_jobs_on_comfyui_job_id"
    t.index ["image_candidate_id"], name: "index_comfyui_jobs_on_image_candidate_id"
    t.index ["job_payload"], name: "index_comfyui_jobs_on_job_payload", using: :gin
    t.index ["parent_candidate_id"], name: "index_comfyui_jobs_on_parent_candidate_id"
    t.index ["pipeline_run_id"], name: "index_comfyui_jobs_on_pipeline_run_id"
    t.index ["pipeline_step_id"], name: "index_comfyui_jobs_on_pipeline_step_id"
    t.index ["status"], name: "index_comfyui_jobs_on_status"
  end

  create_table "image_candidates", force: :cascade do |t|
    t.bigint "pipeline_step_id", null: false
    t.bigint "parent_id"
    t.string "image_path"
    t.integer "elo_score", default: 1000, null: false
    t.string "status", default: "active", null: false
    t.integer "child_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pipeline_run_id"
    t.integer "vote_count", default: 0, null: false
    t.index ["elo_score"], name: "index_image_candidates_on_elo_score"
    t.index ["parent_id"], name: "index_image_candidates_on_parent_id"
    t.index ["pipeline_run_id"], name: "index_image_candidates_on_pipeline_run_id"
    t.index ["pipeline_step_id"], name: "index_image_candidates_on_pipeline_step_id"
    t.index ["status", "child_count"], name: "index_image_candidates_on_status_and_child_count"
    t.index ["vote_count"], name: "index_image_candidates_on_vote_count"
  end

  create_table "pipeline_runs", force: :cascade do |t|
    t.bigint "pipeline_id", null: false
    t.string "name"
    t.string "target_folder"
    t.jsonb "variables", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_id"], name: "index_pipeline_runs_on_pipeline_id"
    t.index ["status"], name: "index_pipeline_runs_on_status"
    t.index ["variables"], name: "index_pipeline_runs_on_variables", using: :gin
  end

  create_table "pipeline_steps", force: :cascade do |t|
    t.bigint "pipeline_id", null: false
    t.string "name", null: false
    t.integer "order", null: false
    t.text "comfy_workflow_json", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "needs_run_prompt", default: false, null: false
    t.boolean "needs_parent_image_path", default: false, null: false
    t.boolean "needs_run_variables", default: false, null: false
    t.index ["pipeline_id", "order"], name: "index_pipeline_steps_on_pipeline_id_and_order", unique: true
    t.index ["pipeline_id"], name: "index_pipeline_steps_on_pipeline_id"
  end

  create_table "pipelines", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_pipelines_on_name"
  end

  add_foreign_key "comfyui_jobs", "image_candidates"
  add_foreign_key "comfyui_jobs", "image_candidates", column: "parent_candidate_id"
  add_foreign_key "comfyui_jobs", "pipeline_runs"
  add_foreign_key "comfyui_jobs", "pipeline_steps"
  add_foreign_key "image_candidates", "image_candidates", column: "parent_id"
  add_foreign_key "image_candidates", "pipeline_runs"
  add_foreign_key "image_candidates", "pipeline_steps"
  add_foreign_key "pipeline_runs", "pipelines"
  add_foreign_key "pipeline_steps", "pipelines"
end
