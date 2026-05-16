require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @account = accounts(:one)
    sign_in @user
  end

  test "index lists user accounts with balance" do
    get dashboard_accounts_url
    assert_select "h2", text: /Contas/
    assert_select "h3", text: /Conta Corrente/
  end

  test "index does not show other users accounts" do
    get dashboard_accounts_url
    assert_no_match /Poupança/, response.body
  end

  test "index returns JSON with account attributes" do
    get dashboard_accounts_url(format: :json)
    assert_equal "application/json", response.media_type
    data = response.parsed_body
    assert_kind_of Array, data
    account = data.find { |a| a["name"] == "Conta Corrente" }
    assert account
    assert_equal "checking", account["account_type"]
    assert_equal 1000000, account["balance"]
  end

  test "new renders form fields" do
    get new_dashboard_account_url
    assert_select "input[name='account[name]']"
    assert_select "select[name='account[account_type]']"
    assert_select "input[name='account[balance]']"
  end

  test "create persists with balance converted to cents" do
    assert_difference("Account.count") do
      post dashboard_accounts_url, params: {
        account: { name: "Nova Conta", account_type: "checking", balance: "1500.50", currency: "BRL", color: "indigo" }
      }
    end
    created = Account.last
    assert_equal "Nova Conta", created.name
    assert_equal "checking", created.account_type
    assert_equal 150050, created.balance
    assert_equal "BRL", created.currency
    assert_redirected_to dashboard_accounts_path
  end

  test "edit form is pre-filled" do
    get edit_dashboard_account_url(@account)
    assert_select "input[name='account[name]'][value='Conta Corrente']"
  end

  test "update changes attributes and redirects" do
    patch dashboard_account_url(@account), params: { account: { name: "Conta Atualizada", color: "emerald" } }
    @account.reload
    assert_equal "Conta Atualizada", @account.name
    assert_equal "emerald", @account.color
    assert_redirected_to dashboard_accounts_path
  end

  test "destroy removes account and nullifies transactions" do
    tx_id = transactions(:one).id
    assert_difference("Account.count", -1) { delete dashboard_account_url(@account) }
    assert_nil Transaction.find_by(id: tx_id)
    assert_redirected_to dashboard_accounts_path
  end

  test "cannot access other user's account" do
    get edit_dashboard_account_url(accounts(:two))
    assert_response :not_found
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_accounts_url
    assert_redirected_to new_user_session_path
  end
end