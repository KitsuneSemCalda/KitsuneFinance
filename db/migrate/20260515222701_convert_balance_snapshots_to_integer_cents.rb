class ConvertBalanceSnapshotsToIntegerCents < ActiveRecord::Migration[8.1]
  def up
    change_column :balance_snapshots, :total_balance, :integer, default: 0, null: false
    change_column :balance_snapshots, :total_investments, :integer, default: 0, null: false
    change_column :balance_snapshots, :net_worth, :integer, default: 0, null: false
  end

  def down
    change_column :balance_snapshots, :total_balance, :decimal, precision: 15, scale: 2, null: false
    change_column :balance_snapshots, :total_investments, :decimal, precision: 15, scale: 2, default: "0.0", null: false
    change_column :balance_snapshots, :net_worth, :decimal, precision: 15, scale: 2, null: false
  end
end
