class RemoveUnusedBalanceFromBalanceSnapshots < ActiveRecord::Migration[8.1]
  def change
    remove_column :balance_snapshots, :balance, :integer
  end
end
