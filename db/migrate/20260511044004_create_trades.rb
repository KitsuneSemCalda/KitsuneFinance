class CreateTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :trades do |t|
      t.references :user, null: false, foreign_key: true
      t.references :investment, null: false, foreign_key: true
      t.string :trade_type, null: false
      t.decimal :quantity, precision: 15, scale: 6, null: false
      t.integer :price, null: false, default: 0
      t.date :date, null: false
      t.text :notes

      t.timestamps
    end

    add_index :trades, [:investment_id, :date]
  end
end
