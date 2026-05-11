class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  def index
    @page_title = "Visão Geral"

    # Real data from associations
    @accounts = current_user.accounts
    @net_worth = @accounts.sum(:balance) + current_user.investments.sum { |i| i.current_value }
    
    # Monthly savings and debt simulation
    @monthly_income = current_user.transactions.income.current_month.sum(:amount)
    @monthly_expense = current_user.transactions.expense.current_month.sum(:amount)
    @monthly_debts = current_user.debts.sum(:monthly_payment)
    @monthly_savings = @monthly_income - (@monthly_expense + @monthly_debts)

    @portfolio_total = current_user.investments.sum { |i| i.current_value }
    # Calculation for portfolio change would require history, for now we sum current vs cost
    total_cost = current_user.investments.sum { |i| i.total_cost }
    @portfolio_change = @portfolio_total - total_cost
    @portfolio_change_pct = (total_cost.present? && total_cost.to_f > 0) ? ((@portfolio_total.to_f / total_cost.to_f) - 1) * 100 : 0

    @recent_transactions = current_user.transactions.recent.map do |tx|
      {
        icon: tx.category&.icon || "💰",
        description: tx.description,
        category: tx.category&.name || "Sem categoria",
        date: tx.date.strftime("%d %b"),
        amount: tx.amount,
        type: tx.transaction_type.to_sym
      }
    end

    @goals = current_user.goals.limit(3).map do |goal|
      {
        name: goal.name,
        icon: goal.icon,
        current: goal.current_amount,
        target: goal.target_amount,
        color: goal.color
      }
    end

    # Allocation data
    @allocation = current_user.investments.group(:asset_type).sum("quantity * current_price")
    @allocation_total = @allocation.values.sum
    @allocation_json = @allocation.map { |k, v| { label: I18n.t("activerecord.enums.investment.asset_type.#{k}", default: k.to_s.humanize), value: v } }.to_json

    # Cash Flow data (last 30 days)
    @cash_flow_labels = (29.days.ago.to_date..Date.today).map { |d| d.strftime("%d/%m") }
    
    income_data = current_user.transactions.income.where(date: 29.days.ago..Date.today).group(:date).sum(:amount)
    expense_data = current_user.transactions.expense.where(date: 29.days.ago..Date.today).group(:date).sum(:amount)

    @income_series = (29.days.ago.to_date..Date.today).map { |d| income_data[d] || 0 }
    @expense_series = (29.days.ago.to_date..Date.today).map { |d| expense_data[d] || 0 }
  end

  def transactions
    @page_title = "Transações"
    render :coming_soon
  end

  def budget
    @page_title = "Orçamento"
    render :coming_soon
  end

  def investments
    @page_title = "Investimentos"
    render :coming_soon
  end

  def goals
    @page_title = "Metas"
    render :coming_soon
  end

  def reports
    @page_title = "Relatórios"
    
    # Summary data
    @total_income = current_user.transactions.income.sum(:amount)
    @total_expense = current_user.transactions.expense.sum(:amount)
    @balance = @total_income - @total_expense

    # Monthly data for the last 6 months
    @monthly_data = (0..5).reverse_each.map do |i|
      date = i.months.ago.beginning_of_month
      {
        month: l(date, format: "%b/%y"),
        income: current_user.transactions.income.where(date: date..date.end_of_month).sum(:amount),
        expense: current_user.transactions.expense.where(date: date..date.end_of_month).sum(:amount)
      }
    end

    # Category distribution (Expenses)
    @category_distribution = current_user.transactions.expense
                                        .joins(:category)
                                        .group("categories.name")
                                        .sum(:amount)
                                        .sort_by { |_name, amount| -amount }
                                        .first(5)

    # Export links metadata
    @export_formats = [
      { name: "Transações (CSV)", path: dashboard_transactions_path(format: :csv), icon: "csv" },
      { name: "Transações (Excel)", path: dashboard_transactions_path(format: :xlsx), icon: "xlsx" },
      { name: "Metas (CSV)", path: dashboard_goals_path(format: :csv), icon: "csv" },
      { name: "Metas (Excel)", path: dashboard_goals_path(format: :xlsx), icon: "xlsx" }
    ]
  end

  def simulation
    @page_title = "Simulação Financeira"
    engine = SimulationEngine.new(current_user)
    
    scenario = {
      salary_adjustment: params[:salary_adj].to_f / 100,
      expense_adjustment: params[:expense_adj].to_f / 100
    }
    
    @results = engine.forecast(scenario)
  end

  def settings
    @page_title = "Configurações"
    @user = current_user
  end

  def update_settings
    @user = current_user
    params[:user][:monthly_salary] = (params[:user][:monthly_salary].to_f * 100).to_i if params[:user][:monthly_salary].present?
    
    if @user.update(user_params)
      redirect_to dashboard_settings_path, notice: "Configurações atualizadas com sucesso."
    else
      render :settings, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:primary_currency, :locale, :ntfy_url, :monthly_salary, :brapi_token)
  end
end
