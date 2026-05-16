class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  def index
    @page_title = "Visão Geral"
    d = DashboardDataService.new(current_user)

    @insights = d.insights

    m = d.financial_health
    @net_worth = m[:net_worth]
    @monthly_income = m[:monthly_income]
    @monthly_expense = m[:monthly_expense]
    @monthly_debts = m[:monthly_debts]
    @monthly_savings = m[:monthly_savings]
    @salary_present = m[:salary_present]
    @expense_ratio = m[:expense_ratio]
    @dti = m[:dti]
    @savings_rate = m[:savings_rate]
    @net_worth_to_annual = m[:net_worth_to_annual]
    @health_score = m[:health_score]

    @recent_transactions_more = d.recent_transactions_more
    @yearly_data = d.yearly_summary

    pm = d.portfolio_metrics
    @portfolio_total = pm[:total]
    @portfolio_change = pm[:change]
    @portfolio_change_pct = pm[:change_pct]
    @goals = d.goals

    alloc = d.allocation
    @allocation = alloc[:by_type]
    @allocation_total = alloc[:total]
    @allocation_json = alloc[:json]

    @budgets_with_progress = d.budgets_with_progress

    @available_balance = d.available_balance
    @investment_count = d.investment_count
    @bills_pending = d.bills_pending
    @bills_overdue_count = d.bills_overdue_count
    @recent_trades = d.recent_trades

    cf60 = d.cash_flow_60
    @cash_flow_labels_60 = cf60[:labels]
    @income_series_60 = cf60[:income]
    @expense_series_60 = cf60[:expense]

    dt = d.debt_timeline
    @total_debt_remaining = dt[:total_remaining]
    @debt_progress_pct = dt[:progress_pct]
    @debt_estimated_months = dt[:estimated_months]
  end

  def health
    @page_title = "Saúde Financeira"
    d = DashboardDataService.new(current_user)

    m = d.financial_health
    @salary = m[:salary]
    @salary_present = m[:salary_present]
    @monthly_income = m[:monthly_income]
    @monthly_expense = m[:monthly_expense]
    @monthly_debts = m[:monthly_debts]
    @monthly_savings = m[:monthly_savings]
    @net_worth = m[:net_worth]
    @dti = m[:dti]
    @expense_ratio = m[:expense_ratio]
    @savings_rate = m[:savings_rate]
    @net_worth_to_annual = m[:net_worth_to_annual]
    @health_score = m[:health_score]

    @investments = d.health_investments
    @allocation = d.health_allocation
    @total_gain_loss = d.total_gain_loss

    @goals = d.health_goals
    @goals_completed = @goals.where(status: "completed").count
    @goals_active = @goals.where(status: "active").count
    @goals_total = @goals.count
    @debt_progress = d.debt_progress

    @recommendations = d.recommendations
  end

  def reports
    @page_title = "Relatórios"
    d = DashboardDataService.new(current_user)

    rs = d.reports_summary
    @total_income = rs[:total_income]
    @total_expense = rs[:total_expense]
    @balance = rs[:balance]

    @monthly_data = d.monthly_report_data
    @category_distribution = d.category_distribution
    ri = d.reports_indicators
    @expense_ratio = ri[:expense_ratio]
    @savings_rate = ri[:salary_present] ? ((@total_income - @total_expense).to_f / ri[:salary]) * 100 : nil
    @dti = ri[:dti]
    @salary = ri[:salary]
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

  def news
    @page_title = "Notícias Financeiras"
    @articles = NewsFeedService.fetch_latest(20)
  end

  def indicators
    @page_title = "Indicadores Econômicos"
    @selic = IndicatorsService.fetch_latest(:selic)
    @cdi = IndicatorsService.fetch_latest(:cdi)
    @ipca = IndicatorsService.fetch_latest(:ipca)
  end

  def backup
    @page_title = "Backup"

    data = {
      exported_at: Time.current.iso8601,
      user: { email: current_user.email, monthly_salary: current_user.monthly_salary },
      accounts: current_user.accounts.as_json(only: %i[name account_type balance currency color icon bank_code bank_name]),
      categories: current_user.categories.as_json(only: %i[name transaction_type color icon]),
      transactions: current_user.transactions.as_json(only: %i[description amount transaction_type date account_id category_id notes]),
      investments: current_user.investments.as_json(only: %i[name ticker asset_type quantity avg_price current_price currency notes]),
      goals: current_user.goals.as_json(only: %i[name target_amount current_amount status deadline color]),
      debts: current_user.debts.as_json(only: %i[name total_amount monthly_payment installments_count remaining_installments]),
      bill_reminders: current_user.bill_reminders.as_json(only: %i[name amount due_date paid recurrent recurrence_period notes]),
      budgets: current_user.budgets.as_json(only: %i[month year limit_amount category_id]),
      trades: current_user.trades.as_json(only: %i[trade_type quantity price date investment_id])
    }

    backup_json = JSON.pretty_generate(data)
    send_data backup_json, filename: "kitsune-backup-#{Date.today}.json", type: "application/json"
  end

  def settings
    @page_title = "Configurações"
    @user = current_user
    @tab = %w[profile preferences dashboard integrations account].include?(params[:tab]) ? params[:tab] : "profile"
  end

  def update_settings
    @user = current_user
    @tab = %w[profile preferences dashboard integrations account].include?(params[:tab]) ? params[:tab] : "profile"
    params[:user][:monthly_salary] = cents_from_string(params[:user][:monthly_salary]) if params[:user][:monthly_salary].present?
    
    if @user.update(user_params)
      redirect_to dashboard_settings_path(tab: @tab), notice: "Configurações atualizadas com sucesso."
    else
      render :settings, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:primary_currency, :locale, :ntfy_url, :monthly_salary, :brapi_token)
  end
end
