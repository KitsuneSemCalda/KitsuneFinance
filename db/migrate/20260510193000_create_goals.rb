class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name,           null: false
      t.string  :icon,           default: "🎯"
      t.decimal :target_amount,  precision: 15, scale: 2, null: false
      t.decimal :current_amount, precision: 15, scale: 2, null: false, default: 0
      t.date    :deadline
      t.string  :color,          default: "indigo"
      t.string  :status,         null: false, default: "active" # active | completed | paused
      t.text    :notes

      t.timestamps
    end
  end
end
