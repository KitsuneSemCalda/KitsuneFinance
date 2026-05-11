class AddPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :primary_currency, :string
    add_column :users, :ntfy_url, :string
  end
end
