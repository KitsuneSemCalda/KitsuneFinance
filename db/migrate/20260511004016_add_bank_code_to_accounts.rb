class AddBankCodeToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :bank_code, :string
    add_column :accounts, :bank_name, :string
  end
end
