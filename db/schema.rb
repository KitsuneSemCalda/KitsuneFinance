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

ActiveRecord::Schema[8.1].define(version: 2026_05_11_044005) do
  create_table "accounts", force: :cascade do |t|
    t.string "account_type", default: "checking", null: false
    t.integer "balance", default: 0
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

  create_table "balance_snapshots", force: :cascade do |t|
    t.integer "balance", default: 0
    t.datetime "created_at", null: false
    t.decimal "net_worth", precision: 15, scale: 2, null: false
    t.date "snapshot_date", null: false
    t.decimal "total_balance", precision: 15, scale: 2, null: false
    t.decimal "total_investments", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "snapshot_date"], name: "index_balance_snapshots_on_user_id_and_snapshot_date", unique: true
    t.index ["user_id"], name: "index_balance_snapshots_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.datetime "alert_100_sent_at"
    t.datetime "alert_80_sent_at"
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.integer "limit_amount", default: 0
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
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "categorization_rules", force: :cascade do |t|
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.string "keyword"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["category_id"], name: "index_categorization_rules_on_category_id"
    t.index ["user_id"], name: "index_categorization_rules_on_user_id"
  end

  create_table "debts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "installments_count"
    t.integer "monthly_payment"
    t.string "name"
    t.integer "remaining_installments"
    t.integer "total_amount"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_debts_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.string "color", default: "indigo"
    t.datetime "created_at", null: false
    t.integer "current_amount", default: 0
    t.date "deadline"
    t.string "icon", default: "🎯"
    t.string "name", null: false
    t.text "notes"
    t.string "status", default: "active", null: false
    t.integer "target_amount", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "investments", force: :cascade do |t|
    t.string "asset_type", null: false
    t.integer "avg_price", default: 0
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
    t.index ["user_id", "ticker"], name: "index_investments_on_user_id_and_ticker"
    t.index ["user_id"], name: "index_investments_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "link"
    t.string "message"
    t.string "notification_type"
    t.datetime "read_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
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
    t.index ["user_id"], name: "index_trades_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "amount", default: 0
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "description", null: false
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
    t.index ["goal_id"], name: "index_transactions_on_goal_id"
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
  add_foreign_key "balance_snapshots", "users"
  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "categorization_rules", "categories"
  add_foreign_key "categorization_rules", "users"
  add_foreign_key "debts", "users"
  add_foreign_key "goals", "users"
  add_foreign_key "investments", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "trades", "investments"
  add_foreign_key "trades", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "goals"
  add_foreign_key "transactions", "users"
end
