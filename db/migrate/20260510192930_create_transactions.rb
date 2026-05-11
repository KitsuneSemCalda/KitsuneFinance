class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :account,  null: false, foreign_key: true
      t.references :category, null: true,  foreign_key: true
      t.references :goal,     null: true,  foreign_key: true
      t.string  :description,       null: false
      t.decimal :amount,            precision: 15, scale: 2, null: false
      t.string  :transaction_type,  null: false  # income | expense | transfer
      t.date    :date,              null: false
      t.text    :notes
      t.boolean :recurrent,         default: false, null: false
      t.string  :recurrence_period  # monthly | weekly | yearly

      t.timestamps
    end

    add_index :transactions, [ :user_id, :date ]
    add_index :transactions, [ :user_id, :transaction_type ]
  end
end
