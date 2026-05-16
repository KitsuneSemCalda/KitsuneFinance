require "test_helper"

class BillRemindersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @bill = bill_reminders(:one)
    sign_in @user
  end

  test "index lists user bills" do
    get dashboard_bill_reminders_url
    assert_select "p", text: /Aluguel/
    assert_select "p", text: /Internet/
    assert_no_match /Outra/, response.body
  end

  test "new renders form fields" do
    get new_dashboard_bill_reminder_url
    assert_select "input[name='bill_reminder[name]']"
    assert_select "input[name='bill_reminder[amount]']"
    assert_select "input[name='bill_reminder[due_date]']"
    assert_select "input[name='bill_reminder[recurrent]']"
  end

  test "create defaults paid to false" do
    assert_difference("BillReminder.count") do
      post dashboard_bill_reminders_url, params: {
        bill_reminder: { name: "Condomínio", amount: 80000, due_date: Date.today + 10,
                         category_id: categories(:one).id }
      }
    end
    created = BillReminder.last
    assert_equal "Condomínio", created.name
    assert_equal 80000, created.amount
    assert_equal false, created.paid
    assert_redirected_to dashboard_bill_reminders_path
  end

  test "edit form is pre-filled" do
    get edit_dashboard_bill_reminder_url(@bill)
    assert_select "input[name='bill_reminder[name]'][value=?]", @bill.name
  end

  test "update changes attributes" do
    patch dashboard_bill_reminder_url(@bill), params: { bill_reminder: { name: "Aluguel Novo" } }
    @bill.reload
    assert_equal "Aluguel Novo", @bill.name
    assert_redirected_to dashboard_bill_reminders_path
  end

  test "toggle paid status" do
    patch dashboard_bill_reminder_url(@bill), params: { bill_reminder: { paid: true } }
    assert @bill.reload.paid
    assert_redirected_to dashboard_bill_reminders_path
  end

  test "destroy removes bill" do
    assert_difference("BillReminder.count", -1) { delete dashboard_bill_reminder_url(@bill) }
    assert_redirected_to dashboard_bill_reminders_path
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_bill_reminders_url
    assert_redirected_to new_user_session_path
  end
end