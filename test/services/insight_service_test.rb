require "test_helper"

class InsightServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "generate returns array" do
    insights = InsightService.generate(@user)
    assert_kind_of Array, insights
  end

  test "insights have title, message and type" do
    insights = InsightService.generate(@user)
    insights.each do |insight|
      assert_includes insight.keys, :title
      assert_includes insight.keys, :message
      assert_includes insight.keys, :type
    end
  end

  test "returns top category insight when transactions exist" do
    insights = InsightService.generate(@user)
    has_category_insight = insights.any? { |i| i[:title] == "Categoria em Destaque" }
    assert has_category_insight
  end

  test "returns empty array for user with no transactions" do
    Transaction.where(user: @user).destroy_all
    insights = InsightService.generate(@user)
    assert_equal [], insights
  end

  test "warning insight when current expenses exceed past average" do
    Transaction.where(user: @user).destroy_all
    @user.transactions.create!(
      account: accounts(:one), category: categories(:one),
      description: "Alta", amount: 500000,
      transaction_type: "expense", date: Date.today
    )
    @user.transactions.create!(
      account: accounts(:one), category: categories(:one),
      description: "Baixa", amount: 1000,
      transaction_type: "expense", date: 2.months.ago
    )
    insights = InsightService.generate(@user)
    has_warning = insights.any? { |i| i[:type] == "warning" }
    assert has_warning
  end

  test "success insight when expenses decreased significantly" do
    Transaction.where(user: @user).destroy_all
    @user.transactions.create!(
      account: accounts(:one), category: categories(:one),
      description: "Gasto Baixo", amount: 500,
      transaction_type: "expense", date: Date.today
    )
    @user.transactions.create!(
      account: accounts(:one), category: categories(:one),
      description: "Gasto Alto", amount: 50000,
      transaction_type: "expense", date: 2.months.ago
    )
    insights = InsightService.generate(@user)
    has_success = insights.any? { |i| i[:type] == "success" }
    assert has_success
  end
end