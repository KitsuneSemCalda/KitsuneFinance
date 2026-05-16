class AddDatabaseConstraints < ActiveRecord::Migration[8.1]
  def up
    # --- NOT NULL constraints to match model validations ---

    # Debts
    execute "UPDATE debts SET name = 'Dívida' WHERE name IS NULL"
    change_column_null :debts, :name, false
    change_column_default :debts, :total_amount, 0
    execute "UPDATE debts SET total_amount = 0 WHERE total_amount IS NULL"
    change_column_null :debts, :total_amount, false
    change_column_default :debts, :monthly_payment, 0
    execute "UPDATE debts SET monthly_payment = 0 WHERE monthly_payment IS NULL"
    change_column_null :debts, :monthly_payment, false
    change_column_default :debts, :installments_count, 0
    execute "UPDATE debts SET installments_count = 0 WHERE installments_count IS NULL"
    change_column_null :debts, :installments_count, false
    change_column_default :debts, :remaining_installments, 0
    execute "UPDATE debts SET remaining_installments = 0 WHERE remaining_installments IS NULL"
    change_column_null :debts, :remaining_installments, false

    # Goals
    change_column_default :goals, :current_amount, 0
    execute "UPDATE goals SET current_amount = 0 WHERE current_amount IS NULL"
    change_column_null :goals, :current_amount, false
    change_column_default :goals, :target_amount, 0
    execute "UPDATE goals SET target_amount = 0 WHERE target_amount IS NULL"
    change_column_null :goals, :target_amount, false

    # Budgets
    execute "UPDATE budgets SET limit_amount = 0 WHERE limit_amount IS NULL"
    change_column_null :budgets, :limit_amount, false

    # Notifications
    execute "UPDATE notifications SET title = '' WHERE title IS NULL"
    change_column_null :notifications, :title, false
    execute "UPDATE notifications SET message = '' WHERE message IS NULL"
    change_column_null :notifications, :message, false
    execute "UPDATE notifications SET notification_type = 'info' WHERE notification_type IS NULL"
    change_column_null :notifications, :notification_type, false

    # Categorization rules
    execute "UPDATE categorization_rules SET keyword = '' WHERE keyword IS NULL"
    change_column_null :categorization_rules, :keyword, false
    execute "UPDATE categorization_suggestions SET keyword = '' WHERE keyword IS NULL"
    change_column_null :categorization_suggestions, :keyword, false

    # Accounts
    execute "UPDATE accounts SET balance = 0 WHERE balance IS NULL"
    change_column_null :accounts, :balance, false

    # Investments
    execute "UPDATE investments SET avg_price = 0 WHERE avg_price IS NULL"
    change_column_null :investments, :avg_price, false

    # --- Composite indexes for common query patterns ---

    # Trades filtered by user and sorted by date
    execute "CREATE INDEX IF NOT EXISTS idx_trades_on_user_id_date ON trades(user_id, date)"

    # Notifications filtered by user and unread
    execute "CREATE INDEX IF NOT EXISTS idx_notifications_on_user_id_read_at ON notifications(user_id, read_at)"

    # Bill reminders filtered by user and paid status
    execute "CREATE INDEX IF NOT EXISTS idx_bill_reminders_on_user_id_paid ON bill_reminders(user_id, paid)"

    # Goals filtered by status
    execute "CREATE INDEX IF NOT EXISTS idx_goals_on_status ON goals(status)"

    # Investments grouped by asset_type
    execute "CREATE INDEX IF NOT EXISTS idx_investments_on_asset_type ON investments(asset_type)"

    # Categories filtered by type
    execute "CREATE INDEX IF NOT EXISTS idx_categories_on_transaction_type ON categories(transaction_type)"
  end

  def down
    # Revert NOT NULL
    change_column_null :debts, :name, true
    change_column_default :debts, :total_amount, nil
    change_column_null :debts, :total_amount, true
    change_column_default :debts, :monthly_payment, nil
    change_column_null :debts, :monthly_payment, true
    change_column_default :debts, :installments_count, nil
    change_column_null :debts, :installments_count, true
    change_column_default :debts, :remaining_installments, nil
    change_column_null :debts, :remaining_installments, true

    change_column_null :goals, :current_amount, true
    change_column_null :goals, :target_amount, true
    change_column_null :budgets, :limit_amount, true

    change_column_null :notifications, :title, true
    change_column_null :notifications, :message, true
    change_column_null :notifications, :notification_type, true

    change_column_null :categorization_rules, :keyword, true
    change_column_null :categorization_suggestions, :keyword, true

    change_column_null :accounts, :balance, true
    change_column_null :investments, :avg_price, true

    # Revert indexes
    execute "DROP INDEX IF EXISTS idx_trades_on_user_id_date"
    execute "DROP INDEX IF EXISTS idx_notifications_on_user_id_read_at"
    execute "DROP INDEX IF EXISTS idx_bill_reminders_on_user_id_paid"
    execute "DROP INDEX IF EXISTS idx_goals_on_status"
    execute "DROP INDEX IF EXISTS idx_investments_on_asset_type"
    execute "DROP INDEX IF EXISTS idx_categories_on_transaction_type"
  end
end
