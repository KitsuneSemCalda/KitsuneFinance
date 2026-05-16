class CreateCategorizationSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :categorization_suggestions do |t|
      t.string :keyword
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
