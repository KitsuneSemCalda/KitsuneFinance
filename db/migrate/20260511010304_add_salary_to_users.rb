class AddSalaryToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :monthly_salary, :integer
  end
end
