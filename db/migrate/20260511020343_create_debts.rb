class CreateDebts < ActiveRecord::Migration[8.1]
  def change
    create_table :debts do |t|
      t.string :name
      t.integer :total_amount
      t.integer :monthly_payment
      t.integer :installments_count
      t.integer :remaining_installments
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
