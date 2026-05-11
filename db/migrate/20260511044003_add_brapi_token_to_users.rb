class AddBrapiTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :brapi_token, :string
  end
end
