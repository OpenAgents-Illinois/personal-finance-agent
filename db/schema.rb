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

ActiveRecord::Schema[8.1].define(version: 2026_03_14_193713) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "account_subtype"
    t.string "account_type"
    t.decimal "available_balance", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.decimal "current_balance", precision: 15, scale: 2
    t.string "iso_currency_code"
    t.string "name", null: false
    t.string "plaid_account_id", null: false
    t.bigint "plaid_item_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["plaid_account_id"], name: "index_accounts_on_plaid_account_id", unique: true
    t.index ["plaid_item_id"], name: "index_accounts_on_plaid_item_id"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "plaid_items", force: :cascade do |t|
    t.string "access_token_encrypted", null: false
    t.datetime "created_at", null: false
    t.string "institution_id"
    t.string "institution_name"
    t.string "last_sync_cursor"
    t.datetime "last_synced_at"
    t.string "plaid_item_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["plaid_item_id"], name: "index_plaid_items_on_plaid_item_id", unique: true
    t.index ["user_id"], name: "index_plaid_items_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.date "authorized_date"
    t.string "category_detailed"
    t.string "category_primary"
    t.datetime "created_at", null: false
    t.string "merchant_name"
    t.string "name", null: false
    t.boolean "pending", default: false, null: false
    t.string "plaid_transaction_id", null: false
    t.date "posted_date"
    t.jsonb "raw_payload_json"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["plaid_transaction_id"], name: "index_transactions_on_plaid_transaction_id", unique: true
    t.index ["user_id", "posted_date"], name: "index_transactions_on_user_id_and_posted_date"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "onboarding_completed_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "plaid_items"
  add_foreign_key "accounts", "users"
  add_foreign_key "plaid_items", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "users"
end
