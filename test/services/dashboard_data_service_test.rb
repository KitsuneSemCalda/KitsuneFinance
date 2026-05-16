require "test_helper"

class DashboardDataServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.update!(monthly_salary: 500000)
    @service = DashboardDataService.new(@user)
  end

  test "insights returns array" do
    assert_kind_of Array, @service.insights
  end

  test "accounts returns user accounts" do
    assert_equal @user.accounts.to_a, @service.accounts
  end

  test "financial_health returns hash with expected keys" do
    keys = %i[salary salary_present monthly_income monthly_expense monthly_debts
              monthly_savings net_worth dti expense_ratio savings_rate
              net_worth_to_annual health_score]
    result = @service.financial_health
    assert_kind_of Hash, result
    keys.each { |k| assert_includes result, k }
  end

  test "yearly_summary returns 12 months" do
    data = @service.yearly_summary
    assert_equal 12, data.length
    data.each do |entry|
      assert_includes entry, :month
      assert_includes entry, :income
      assert_includes entry, :expense
    end
  end

  test "portfolio_metrics contains expected keys" do
    pm = @service.portfolio_metrics
    assert_includes pm, :total
    assert_includes pm, :change
    assert_includes pm, :change_pct
  end

  test "recent_transactions returns formatted transactions" do
    txs = @service.recent_transactions
    refute_empty txs
    assert_includes txs.first, :icon
    assert_includes txs.first, :description
    assert_includes txs.first, :amount
  end

  test "goals returns up to 3 goals" do
    goals = @service.goals
    assert_operator goals.length, :<=, 3
    assert_includes goals.first, :name
    assert_includes goals.first, :pct
    assert_includes goals.first, :estimated_months
  end

  test "allocation has expected keys" do
    alloc = @service.allocation
    assert_includes alloc, :by_type
    assert_includes alloc, :total
    assert_includes alloc, :json
    assert_kind_of String, alloc[:json]
  end

  test "cash_flow_30 has labels, income, expense" do
    cf = @service.cash_flow_30
    assert_includes cf, :labels
    assert_includes cf, :income
    assert_includes cf, :expense
    assert_equal cf[:labels].length, cf[:income].length
    assert_equal cf[:labels].length, cf[:expense].length
  end

  test "cash_flow_60 has labels, income, expense" do
    cf = @service.cash_flow_60
    assert_includes cf, :labels
    assert_includes cf, :income
    assert_includes cf, :expense
  end

  test "available_balance returns integer" do
    assert_kind_of Integer, @service.available_balance
  end

  test "investment_count returns count" do
    assert_equal @user.investments.count, @service.investment_count
  end

  test "bills_pending returns integer" do
    assert_kind_of Integer, @service.bills_pending
  end

  test "bills_overdue_count returns integer" do
    assert_kind_of Integer, @service.bills_overdue_count
  end

  test "recent_trades returns trades with investment included" do
    trades = @service.recent_trades
    trades.each do |t|
      assert t.association(:investment).loaded? if t.respond_to?(:association)
    end
  end

  test "budgets_with_progress returns array with expected keys" do
    budgets = @service.budgets_with_progress
    if budgets.any?
      assert_includes budgets.first, :category
      assert_includes budgets.first, :limit
      assert_includes budgets.first, :spent
      assert_includes budgets.first, :pct
      assert_includes budgets.first, :over
    end
  end

  test "debt_timeline has expected keys" do
    dt = @service.debt_timeline
    assert_includes dt, :total_remaining
    assert_includes dt, :progress_pct
    assert_includes dt, :estimated_months
    assert_includes dt, :next_payment
  end

  test "recommendations returns array" do
    recs = @service.recommendations
    assert_kind_of Array, recs
    recs.each do |r|
      assert_includes r, :type
      assert_includes r, :icon
      assert_includes r, :title
      assert_includes r, :desc
    end
  end

  test "reports_summary has total_income, total_expense, balance" do
    rs = @service.reports_summary
    assert_includes rs, :total_income
    assert_includes rs, :total_expense
    assert_includes rs, :balance
    assert_equal rs[:total_income] - rs[:total_expense], rs[:balance]
  end

  test "monthly_report_data returns 6 months" do
    data = @service.monthly_report_data
    assert_equal 6, data.length
  end

  test "category_distribution returns top 5 categories" do
    dist = @service.category_distribution
    assert_operator dist.length, :<=, 5
  end

  test "health_investments returns investments" do
    assert_equal @user.investments.to_a, @service.health_investments.to_a
  end

  test "health_allocation returns count by type" do
    assert_kind_of Hash, @service.health_allocation
  end

  test "total_gain_loss returns numeric" do
    assert_kind_of Numeric, @service.total_gain_loss
  end

  test "health_goals returns goals" do
    assert_equal @user.goals.to_a, @service.health_goals.to_a
  end

  test "debt_progress returns float" do
    assert_kind_of Float, @service.debt_progress
  end

  test "without salary financial_health handles nil salary" do
    @user.update!(monthly_salary: nil)
    service = DashboardDataService.new(@user)
    m = service.financial_health
    assert_equal false, m[:salary_present]
    assert_nil m[:dti]
  end

  test "with no investments portfolio_metrics returns zeros" do
    @user.investments.destroy_all
    pm = @service.portfolio_metrics
    assert_equal 0, pm[:total]
    assert_equal 0, pm[:change]
    assert_equal 0, pm[:change_pct]
  end
end
