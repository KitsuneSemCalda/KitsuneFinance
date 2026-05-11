class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name,         null: false
      t.string  :account_type, null: false, default: "checking"
      t.decimal :balance,      precision: 15, scale: 2, null: false, default: 0
      t.string  :currency,     null: false, default: "BRL"
      t.string  :color,        default: "indigo"
      t.string  :icon,         default: "🏦"

      t.timestamps
    end
  end
end
