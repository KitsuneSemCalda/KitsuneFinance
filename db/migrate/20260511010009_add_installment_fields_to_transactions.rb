class AddInstallmentFieldsToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :installment_number, :integer
    add_column :transactions, :total_installments, :integer
    add_column :transactions, :parent_transaction_id, :integer
  end
end
