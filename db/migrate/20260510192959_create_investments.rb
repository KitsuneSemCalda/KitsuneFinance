class CreateInvestments < ActiveRecord::Migration[8.1]
  def change
    create_table :investments do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name,          null: false
      t.string  :ticker
      t.string  :asset_type,    null: false # stock_br | fii | fixed_income | international | crypto | other
      t.decimal :quantity,      precision: 15, scale: 6, null: false, default: 0
      t.decimal :avg_price,     precision: 15, scale: 4, null: false, default: 0
      t.decimal :current_price, precision: 15, scale: 4, null: false, default: 0
      t.string  :currency,      null: false, default: "BRL"
      t.date    :purchased_at
      t.text    :notes

      t.timestamps
    end
    add_index :investments, [:user_id, :ticker]
  end
end
