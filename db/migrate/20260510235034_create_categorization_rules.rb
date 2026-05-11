class CreateCategorizationRules < ActiveRecord::Migration[8.1]
  def change
    create_table :categorization_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :keyword

      t.timestamps
    end
  end
end
