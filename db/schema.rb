# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_06_02_103524) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "approvers", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "category_id"
    t.boolean "status", default: true
    t.boolean "changed_status", default: false
    t.string "approver_code"
    t.integer "user_approver_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "approvers_categories", id: :serial, force: :cascade do |t|
    t.string "category_name"
    t.string "client_code"
    t.integer "user_id"
    t.boolean "status", default: true
    t.boolean "changed_status", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "leveled"
  end

  create_table "callback_resps", id: :serial, force: :cascade do |t|
    t.string "trnx_id"
    t.string "mm_trnx_id"
    t.string "mobile_number"
    t.string "resp_code"
    t.string "network"
    t.boolean "status"
    t.string "resp_desc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "csv_uploads", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "client_code"
    t.string "file_name"
    t.string "file_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reference", limit: 255
  end

  create_table "customer_auths", id: :serial, force: :cascade do |t|
    t.string "auth_code"
    t.string "status"
    t.string "customer_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "msgs", id: :serial, force: :cascade do |t|
    t.string "msg_id"
    t.string "phone_number"
    t.text "msg"
    t.string "resp_code"
    t.string "resp_desc"
    t.boolean "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "number_validations", id: :serial, force: :cascade do |t|
    t.string "mobile_number"
    t.string "network"
    t.integer "group_id"
    t.boolean "status"
    t.boolean "changed_status"
    t.integer "user_id"
    t.string "recipient_name"
    t.string "client_code"
    t.string "csv_upload_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payout_approvals", id: :serial, force: :cascade do |t|
    t.integer "payout_id"
    t.string "approver_code"
    t.boolean "approved", default: false
    t.boolean "status"
    t.boolean "notified", default: false
    t.integer "level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "disapproval_reason"
    t.boolean "disapprove"
  end

  create_table "payouts", id: :serial, force: :cascade do |t|
    t.string "title"
    t.boolean "approval_status"
    t.string "approver_cat_id"
    t.text "comment"
    t.boolean "processed"
    t.integer "group_id"
    t.boolean "needs_approval"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "disapproval_reason"
    t.boolean "disapprove"
  end

  create_table "premium_clients", id: :serial, force: :cascade do |t|
    t.string "company_name"
    t.string "client_code"
    t.string "email"
    t.string "contact_number"
    t.string "client_id"
    t.string "client_key"
    t.string "secret_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "status", default: true
    t.boolean "changed_status", default: false
    t.integer "user_id"
    t.string "acronym", limit: 100
    t.string "sms_key", limit: 400
    t.text "success_msg", default: "Your funds has been sent to your wallet successfully."
    t.boolean "needs_approval"
    t.string "sender_id"
  end

  create_table "recipient_groups", id: :serial, force: :cascade do |t|
    t.string "group_desc"
    t.string "client_code"
    t.string "approver_code"
    t.boolean "status", default: true
    t.integer "approver_cat_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recipients", id: :serial, force: :cascade do |t|
    t.string "mobile_number"
    t.string "network"
    t.decimal "amount"
    t.integer "group_id"
    t.boolean "status", default: true
    t.boolean "changed_status", default: false
    t.boolean "disburse_status"
    t.string "transaction_id"
    t.text "fail_reason"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "recipient_name", limit: 200
    t.string "client_code"
    t.string "csv_uploads_id"
    t.string "reference"
    t.string "sort_code"
    t.string "swift_code"
    t.string "bank_code"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "role"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sent_callbacks", id: :serial, force: :cascade do |t|
    t.string "trnx_id"
    t.string "trnx_type"
    t.decimal "amount"
    t.string "network"
    t.boolean "status"
    t.boolean "is_reversal"
    t.string "mobile_number"
    t.string "merchant_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trans_masters", id: :serial, force: :cascade do |t|
    t.string "main_trans_id"
    t.boolean "final_status"
    t.boolean "is_reversal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transaction_reprocesses", id: :serial, force: :cascade do |t|
    t.string "old_trnx_id"
    t.string "new_trnx_id"
    t.decimal "amount"
    t.boolean "status"
    t.boolean "auto"
    t.string "err_code"
    t.integer "user_id"
    t.string "nw_resp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transactions", id: :serial, force: :cascade do |t|
    t.string "mobile_number"
    t.decimal "amount", precision: 12, scale: 2
    t.string "trans_type"
    t.boolean "status"
    t.string "network"
    t.string "transaction_ref_id"
    t.decimal "balance"
    t.string "trnx_type"
    t.string "err_code"
    t.string "nw_resp"
    t.integer "user_id"
    t.boolean "is_reversal"
    t.string "voucher_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "payout_id"
    t.integer "recipient_id"
    t.string "acronym", limit: 50
    t.string "reference"
    t.string "sort_code"
    t.string "swift_code"
    t.string "bank_code"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.integer "role_id"
    t.string "lastname"
    t.string "other_names"
    t.string "mobile_number"
    t.string "client_code"
    t.boolean "active_status", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "creator_id"
    t.boolean "status", default: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_logs", id: :serial, force: :cascade do |t|
    t.integer "idd"
    t.string "email"
    t.string "username"
    t.integer "role_id"
    t.string "lastname"
    t.string "other_names"
    t.string "mobile_number"
    t.string "client_code"
    t.boolean "active_status"
    t.datetime "old_created_at"
    t.string "encrypted_password"
    t.string "reset_password_token"
    t.datetime "reset_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count"
    t.datetime "current_user_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "creator_id"
    t.boolean "status"
    t.boolean "save_status"
    t.integer "user_idd"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted", default: false
  end

end
