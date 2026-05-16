require "test_helper"

class BillReminderTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should be valid with valid attributes" do
    reminder = BillReminder.new(user: @user, name: "Condomínio", amount: 80000, due_date: Date.today + 10)
    assert reminder.valid?
  end

  test "should not be valid without name" do
    reminder = BillReminder.new(user: @user, name: nil, amount: 80000, due_date: Date.today)
    assert_not reminder.valid?
  end

  test "should not be valid without due_date" do
    reminder = BillReminder.new(user: @user, name: "Test", amount: 80000, due_date: nil)
    assert_not reminder.valid?
  end

  test "overdue scope" do
    BillReminder.create!(user: @user, name: "Conta Recente", amount: 5000, due_date: Date.today + 30, paid: false)
    assert_includes BillReminder.overdue.map(&:name), "Aluguel"
    assert_not_includes BillReminder.overdue.map(&:name), "Internet"
  end

  test "upcoming scope" do
    future_reminder = BillReminder.create!(user: @user, name: "Futura", amount: 5000, due_date: Date.today + 7, paid: false)
    assert_includes BillReminder.upcoming.map(&:name), "Futura"
  end

  test "pending scope includes unpaid bills within this month" do
    pending = BillReminder.pending
    assert_not_includes pending.map(&:name), "Internet"
  end

  test "this_month scope" do
    assert_includes BillReminder.this_month.map(&:name), "Aluguel"
  end
end