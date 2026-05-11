class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name,             null: false
      t.string  :transaction_type, null: false  # income | expense
      t.string  :color,            default: "zinc"
      t.string  :icon,             default: "📌"
      t.boolean :system_default,   default: false, null: false

      t.timestamps
    end
  end
end
