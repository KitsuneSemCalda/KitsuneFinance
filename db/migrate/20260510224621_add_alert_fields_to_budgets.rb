class AddAlertFieldsToBudgets < ActiveRecord::Migration[8.1]
  def change
    add_column :budgets, :alert_80_sent_at, :datetime
    add_column :budgets, :alert_100_sent_at, :datetime
  end
end
