class AddDestinationAccountToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :destination_account, foreign_key: { to_table: :accounts }
    add_index :transactions, :parent_transaction_id
    add_index :bill_reminders, :category_id
    add_index :categorization_rules, :keyword
  end
end
