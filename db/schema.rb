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

ActiveRecord::Schema[8.1].define(version: 2026_05_15_231425) do
  create_table "accounts", force: :cascade do |t|
    t.string "account_type", default: "checking", null: false
    t.integer "balance", default: 0, null: false
    t.string "bank_code"
    t.string "bank_name"
    t.string "color", default: "indigo"
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL", null: false
    t.string "icon", default: "🏦"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "balance_snapshots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "net_worth", default: 0, null: false
    t.date "snapshot_date", null: false
    t.integer "total_balance", default: 0, null: false
    t.integer "total_investments", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "snapshot_date"], name: "index_balance_snapshots_on_user_id_and_snapshot_date", unique: true
    t.index ["user_id"], name: "index_balance_snapshots_on_user_id"
  end

  create_table "bill_reminders", force: :cascade do |t|
    t.integer "amount", default: 0
    t.integer "category_id"
    t.string "color", default: "indigo"
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.string "name", null: false
    t.text "notes"
    t.boolean "paid", default: false
    t.string "recurrence_period"
    t.boolean "recurrent", default: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["category_id"], name: "index_bill_reminders_on_category_id"
    t.index ["user_id", "paid"], name: "idx_bill_reminders_on_user_id_paid"
    t.index ["user_id"], name: "index_bill_reminders_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.datetime "alert_100_sent_at"
    t.datetime "alert_80_sent_at"
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.integer "limit_amount", default: 0, null: false
    t.integer "month", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "year", null: false
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["user_id", "category_id", "month", "year"], name: "index_budgets_on_user_category_month_year", unique: true
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "color", default: "zinc"
    t.datetime "created_at", null: false
    t.string "icon", default: "📌"
    t.string "name", null: false
    t.boolean "system_default", default: false, null: false
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["transaction_type"], name: "idx_categories_on_transaction_type"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "categorization_rules", force: :cascade do |t|
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.string "keyword", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["category_id"], name: "index_categorization_rules_on_category_id"
    t.index ["keyword"], name: "index_categorization_rules_on_keyword"
    t.index ["user_id"], name: "index_categorization_rules_on_user_id"
  end

  create_table "categorization_suggestions", force: :cascade do |t|
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.string "keyword", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["category_id"], name: "index_categorization_suggestions_on_category_id"
    t.index ["user_id"], name: "index_categorization_suggestions_on_user_id"
  end

  create_table "debts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "installments_count", default: 0, null: false
    t.integer "monthly_payment", default: 0, null: false
    t.string "name", null: false
    t.integer "remaining_installments", default: 0, null: false
    t.integer "total_amount", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_debts_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.string "color", default: "indigo"
    t.datetime "created_at", null: false
    t.integer "current_amount", default: 0, null: false
    t.date "deadline"
    t.string "icon", default: "🎯"
    t.string "name", null: false
    t.text "notes"
    t.string "status", default: "active", null: false
    t.integer "target_amount", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["status"], name: "idx_goals_on_status"
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "investments", force: :cascade do |t|
    t.string "asset_type", null: false
    t.integer "avg_price", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL", null: false
    t.integer "current_price", default: 0
    t.string "name", null: false
    t.text "notes"
    t.string "price_feed_url"
    t.date "purchased_at"
    t.decimal "quantity", precision: 15, scale: 6, default: "0.0", null: false
    t.string "ticker"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["asset_type"], name: "idx_investments_on_asset_type"
    t.index ["user_id", "ticker"], name: "index_investments_on_user_id_and_ticker"
    t.index ["user_id"], name: "index_investments_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "link"
    t.string "message", null: false
    t.string "notification_type", null: false
    t.datetime "read_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "read_at"], name: "idx_notifications_on_user_id_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "trades", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "investment_id", null: false
    t.text "notes"
    t.integer "price", default: 0, null: false
    t.decimal "quantity", precision: 15, scale: 6, null: false
    t.string "trade_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["investment_id", "date"], name: "index_trades_on_investment_id_and_date"
    t.index ["investment_id"], name: "index_trades_on_investment_id"
    t.index ["user_id", "date"], name: "idx_trades_on_user_id_date"
    t.index ["user_id"], name: "index_trades_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "amount", default: 0
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "description", null: false
    t.integer "destination_account_id"
    t.integer "goal_id"
    t.integer "installment_number"
    t.text "notes"
    t.integer "parent_transaction_id"
    t.string "recurrence_period"
    t.boolean "recurrent", default: false, null: false
    t.integer "total_installments"
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["destination_account_id"], name: "index_transactions_on_destination_account_id"
    t.index ["goal_id"], name: "index_transactions_on_goal_id"
    t.index ["parent_transaction_id"], name: "index_transactions_on_parent_transaction_id"
    t.index ["user_id", "date"], name: "index_transactions_on_user_id_and_date"
    t.index ["user_id", "transaction_type"], name: "index_transactions_on_user_id_and_transaction_type"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "brapi_token"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "locale"
    t.integer "monthly_salary"
    t.string "ntfy_url"
    t.string "primary_currency"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "balance_snapshots", "users"
  add_foreign_key "bill_reminders", "users"
  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "categorization_rules", "categories"
  add_foreign_key "categorization_rules", "users"
  add_foreign_key "categorization_suggestions", "categories"
  add_foreign_key "categorization_suggestions", "users"
  add_foreign_key "debts", "users"
  add_foreign_key "goals", "users"
  add_foreign_key "investments", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "trades", "investments"
  add_foreign_key "trades", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "accounts", column: "destination_account_id"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "goals"
  add_foreign_key "transactions", "users"
end
