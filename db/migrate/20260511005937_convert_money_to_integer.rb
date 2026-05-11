class ConvertMoneyToInteger < ActiveRecord::Migration[8.0]
  def up
    # Accounts
    change_column :accounts, :balance, :integer, default: 0
    
    # Transactions
    change_column :transactions, :amount, :integer, default: 0
    
    # Investments
    change_column :investments, :avg_price, :integer, default: 0
    change_column :investments, :current_price, :integer, default: 0
    
    # Budgets
    change_column :budgets, :limit_amount, :integer, default: 0
    
    # Goals
    change_column :goals, :target_amount, :integer, default: 0
    change_column :goals, :current_amount, :integer, default: 0
    
    # BalanceSnapshots
    change_column :balance_snapshots, :balance, :integer, default: 0
  end

  def down
    # Fallback to float
    change_column :accounts, :balance, :float, default: 0.0
    change_column :transactions, :amount, :float, default: 0.0
    change_column :investments, :avg_price, :float, default: 0.0
    change_column :investments, :current_price, :float, default: 0.0
    change_column :budgets, :limit_amount, :float, default: 0.0
    change_column :goals, :target_amount, :float, default: 0.0
    change_column :goals, :current_amount, :float, default: 0.0
    change_column :balance_snapshots, :balance, :float, default: 0.0
  end
end
