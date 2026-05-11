class CreateBalanceSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :balance_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.date :snapshot_date, null: false
      t.decimal :total_balance, precision: 15, scale: 2, null: false
      t.decimal :total_investments, precision: 15, scale: 2, null: false, default: 0
      t.decimal :net_worth, precision: 15, scale: 2, null: false
      t.timestamps
    end

    add_index :balance_snapshots, [:user_id, :snapshot_date], unique: true
  end
end
