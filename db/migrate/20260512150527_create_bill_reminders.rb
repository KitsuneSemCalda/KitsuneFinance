class CreateBillReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :bill_reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :amount, default: 0
      t.date :due_date, null: false
      t.boolean :recurrent, default: false
      t.string :recurrence_period
      t.boolean :paid, default: false
      t.integer :category_id
      t.text :notes
      t.string :color, default: "indigo"

      t.timestamps
    end
  end
end
