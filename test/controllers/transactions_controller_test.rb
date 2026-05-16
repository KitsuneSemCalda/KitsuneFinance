require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @account = accounts(:one)
    @category = categories(:one)
    @transaction = transactions(:one)
    sign_in @user
  end

  test "index lists user transactions" do
    get dashboard_transactions_url
    assert_select "h2", text: "Transações"
    assert_select "p", text: /Supermercado/
    assert_select "p", text: /Salário/
  end

  test "new renders form fields" do
    get new_dashboard_transaction_url
    assert_select "input[type='radio'][name='transaction[transaction_type]']"
    assert_select "input[name='transaction[amount]']"
    assert_select "select[name='transaction[account_id]']"
    assert_select "input[name='transaction[description]']"
  end

  test "create expense decrements account balance" do
    initial_balance = @account.balance
    assert_difference("Transaction.count") do
      post dashboard_transactions_url, params: {
        transaction: { account_id: @account.id, category_id: @category.id,
                       description: "Almoço", amount: 3000,
                       transaction_type: "expense", date: Date.today }
      }
    end
    created = Transaction.last
    assert_equal "Almoço", created.description
    assert_equal 3000, created.amount
    assert_equal "expense", created.transaction_type
    assert_equal initial_balance - 3000, @account.reload.balance
    assert_redirected_to dashboard_transactions_path
  end

  test "create income increments account balance" do
    initial_balance = @account.balance
    post dashboard_transactions_url, params: {
      transaction: { account_id: @account.id, category_id: @category.id,
                     description: "Freela", amount: 50000,
                     transaction_type: "income", date: Date.today }
    }
    assert_equal initial_balance + 50000, @account.reload.balance
  end

  test "edit form is pre-filled" do
    get edit_dashboard_transaction_url(@transaction)
    assert_select "input[name='transaction[description]'][value=?]", @transaction.description
  end

  test "update amount adjusts balance" do
    prev_amount = @transaction.amount
    balance_before = @account.reload.balance
    patch dashboard_transaction_url(@transaction), params: {
      transaction: { amount: 15000, description: "Supermercado Atualizado" }
    }
    @transaction.reload
    assert_equal "Supermercado Atualizado", @transaction.description
    assert_equal 15000, @transaction.amount
    diff = (-15000) - (-prev_amount)
    assert_equal balance_before + diff, @account.reload.balance
    assert_redirected_to dashboard_transactions_path
  end

  test "destroy reverts account balance" do
    initial = @account.balance
    assert_difference("Transaction.count", -1) { delete dashboard_transaction_url(@transaction) }
    assert_equal initial + @transaction.amount, @account.reload.balance
    assert_redirected_to dashboard_transactions_path
  end

  test "filter by search returns matching transactions" do
    get dashboard_transactions_url, params: { search: "Supermercado" }
    assert_select "p", text: /Supermercado/
    assert_no_match /Salário/, response.body
  end

  test "filter by transaction_type returns only that type" do
    get dashboard_transactions_url, params: { transaction_type: "income" }
    assert_select "p", text: /Salário/
    assert_no_match /Supermercado/, response.body
  end

  test "export CSV" do
    get dashboard_transactions_url(format: :csv)
    assert_equal "text/csv", response.media_type
    assert_match /Supermercado/, response.body
    assert_match /Data;Descrição/, response.body
  end

  test "import page renders account selector" do
    get import_dashboard_transactions_url
    assert_select "select[name='account_id']"
    assert_select "input[type='file']"
  end

  test "do_import with CSV creates transactions" do
    csv_content = "date,description,amount,type\n2026-05-10,Teste CSV,150.50,expense\n2026-05-11,Teste CSV 2,5000.00,income"

    file = Tempfile.new(["import", ".csv"])
    file.write(csv_content)
    file.rewind

    assert_difference("Transaction.count", 2) do
      post do_import_dashboard_transactions_url,
           params: { account_id: @account.id, file: Rack::Test::UploadedFile.new(file, "text/csv") }
    end
    assert_redirected_to dashboard_transactions_path
  ensure
    file&.close
    file&.unlink
  end

  test "do_import without file redirects back" do
    post do_import_dashboard_transactions_url, params: { account_id: @account.id }
    assert_redirected_to import_dashboard_transactions_path
  end

  test "cannot access other user's transaction" do
    other = Transaction.create!(user: users(:two), account: accounts(:two),
                                description: "Secreto", amount: 100,
                                transaction_type: "expense", date: Date.today)
    get edit_dashboard_transaction_url(other)
    assert_response :not_found
  end

  test "requires authentication" do
    sign_out @user
    get dashboard_transactions_url
    assert_redirected_to new_user_session_path
  end
end