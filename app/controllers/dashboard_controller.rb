class DashboardController < ApplicationController
  include FinancialHealth

  before_action :authenticate_user!
  layout "dashboard"

  def index
    @page_title = "Visão Geral"
    @accounts = current_user.accounts
    m = compute_health_metrics(current_user)
    @net_worth = m[:net_worth]
    @monthly_income = m[:monthly_income]
    @monthly_expense = m[:monthly_expense]
    @monthly_debts = m[:monthly_debts]
    @monthly_savings = m[:monthly_savings]
    @salary = m[:salary]
    @salary_present = m[:salary_present]
    @expense_ratio = m[:expense_ratio]
    @dti = m[:dti]
    @savings_rate = m[:savings_rate]
    @net_worth_to_annual = m[:net_worth_to_annual]
    @health_score = m[:health_score]

    @portfolio_total = current_user.investments.sum { |i| i.current_value }
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
      remaining = goal.target_amount - goal.current_amount
      monthly_savings_est = @salary_present ? @salary * 0.1 : nil
      estimated_months = remaining > 0 && monthly_savings_est&.positive? ? (remaining.to_f / monthly_savings_est).ceil : nil
      {
        name: goal.name,
        icon: goal.icon,
        current: goal.current_amount,
        target: goal.target_amount,
        color: goal.color,
        pct: goal.progress_pct,
        estimated_months: estimated_months
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

    # Budget progress
    @month_budgets = current_user.budgets.where(month: Date.today.month, year: Date.today.year)
    @budgets_with_progress = @month_budgets.map do |b|
      {
        category: b.category.name,
        limit: b.limit_amount,
        spent: b.spent_amount,
        pct: b.progress_pct,
        over: b.over_budget?
      }
    end

    # Debt payoff timeline
    debts = current_user.debts
    @total_debt_remaining = debts.sum { |d| d.total_remaining }
    @total_debt_paid = debts.sum { |d| d.total_amount - d.total_remaining }
    @total_debt_original = debts.sum(:total_amount)
    @debt_progress_pct = @total_debt_original > 0 ? (@total_debt_paid.to_f / @total_debt_original) * 100 : 0
    @debt_estimated_months = @monthly_debts > 0 ? (@total_debt_remaining.to_f / @monthly_debts).ceil : nil
    @debt_next_payment = debts.minimum(:monthly_payment) || 0

  end

  def health
    @page_title = "Saúde Financeira"
    m = compute_health_metrics(current_user)
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

    @investments = current_user.investments
    @allocation = current_user.investments.group(:asset_type).count
    @total_gain_loss = @investments.sum { |i| i.gain_loss }

    @goals = current_user.goals
    @goals_completed = @goals.where(status: "completed").count
    @goals_active = @goals.where(status: "active").count
    @goals_total = @goals.count
    total_debt = current_user.debts.sum(:total_amount)
    total_debt_remaining = current_user.debts.sum { |d| d.total_remaining }
    @debt_progress = total_debt > 0 ? ((total_debt - total_debt_remaining).to_f / total_debt) * 100 : 0

    score = 0
    score += 25 if @dti && @dti <= 15; score += 20 if @dti && @dti > 15 && @dti <= 30; score += 15 if @dti && @dti > 30 && @dti <= 40
    score += 25 if @expense_ratio && @expense_ratio <= 25; score += 20 if @expense_ratio && @expense_ratio > 25 && @expense_ratio <= 50; score += 15 if @expense_ratio && @expense_ratio > 50 && @expense_ratio <= 75
    score += 25 if @savings_rate && @savings_rate >= 20; score += 20 if @savings_rate && @savings_rate >= 10 && @savings_rate < 20; score += 15 if @savings_rate && @savings_rate >= 0 && @savings_rate < 10
    score += 25 if @net_worth >= 0; score += 10 if @net_worth == 0
    @health_score = score

    h = ActionController::Base.helpers
    @recommendations = []
    if @dti && @dti > 40
      @recommendations << { type: :danger, icon: "🚨", title: "Endividamento Crítico", desc: "Seu comprometimento de renda com dívidas é de #{h.number_to_percentage(@dti, precision: 1)}. Ideal é manter abaixo de 30%. Considere renegociar prazos ou buscar fontes de renda extra." }
    elsif @dti && @dti > 30
      @recommendations << { type: :warning, icon: "⚠️", title: "Endividamento Elevado", desc: "Seu DTI de #{h.number_to_percentage(@dti, precision: 1)} está acima do recomendado (30%). Evite novas dívidas e foque em quitar as existentes." }
    elsif @dti && @dti <= 15
      @recommendations << { type: :success, icon: "✅", title: "Endividamento Controlado", desc: "Seu DTI de #{h.number_to_percentage(@dti, precision: 1)} está excelente. Você tem boa margem para poupar e investir." }
    end
    if @expense_ratio && @expense_ratio > 75
      @recommendations << { type: :danger, icon: "🔥", title: "Gastos Muito Altos", desc: "Você gasta #{h.number_to_percentage(@expense_ratio, precision: 1)} do seu salário. Tente reduzir para no máximo 50% para ter folga financeira." }
    elsif @expense_ratio && @expense_ratio > 50
      @recommendations << { type: :warning, icon: "📊", title: "Gastos Acima do Ideal", desc: "Seus gastos consomem #{h.number_to_percentage(@expense_ratio, precision: 1)} do salário. A recomendação é manter abaixo de 50%." }
    end
    if @savings_rate && @savings_rate >= 20
      @recommendations << { type: :success, icon: "🏆", title: "Excelente Poupança", desc: "Você poupa #{h.number_to_percentage(@savings_rate, precision: 1)} do salário. Continue assim! Já pensou em direcionar para investimentos de longo prazo?" }
    elsif @savings_rate && @savings_rate >= 10
      @recommendations << { type: :success, icon: "👍", title: "Boa Taxa de Poupança", desc: "Poupando #{h.number_to_percentage(@savings_rate, precision: 1)} do salário, você está no caminho certo. Tente chegar a 20%." }
    elsif @savings_rate && @savings_rate < 0
      @recommendations << { type: :danger, icon: "📉", title: "Orçamento Negativo", desc: "Suas despesas superam sua receita em #{h.number_to_currency(@monthly_savings.abs / 100.0, unit: "R$ ")}. Reveja seus gastos urgentemente." }
    end
    if @net_worth > 0 && @net_worth_to_annual && @net_worth_to_annual < 1
      @recommendations << { type: :info, icon: "💡", title: "Construindo Patrimônio", desc: "Seu patrimônio é de #{h.number_to_percentage(@net_worth_to_annual * 100, precision: 0)} da sua renda anual. Meta: acumular 1 ano de despesas como reserva de emergência." }
    elsif @net_worth > 0 && @net_worth_to_annual && @net_worth_to_annual >= 3
      @recommendations << { type: :success, icon: "🌟", title: "Patrimônio Sólido", desc: "Seu patrimônio equivale a #{h.number_to_percentage(@net_worth_to_annual * 100, precision: 0)} da renda anual. Excelente solidez financeira!" }
    end
    if @investments.none?
      @recommendations << { type: :info, icon: "📈", title: "Comece a Investir", desc: "Você ainda não tem investimentos. Considere alocar parte da sua poupança em ativos como Tesouro Direto, CDBs ou fundos imobiliários." }
    end
    if @goals.active.any? && @goals.active.none? { |g| g.progress_pct > 50 }
      @recommendations << { type: :info, icon: "🎯", title: "Metas em Andamento", desc: "Você tem #{@goals.active.count} meta(s) ativa(s). Foque em concluir a mais próxima para ganhar impulso." }
    end
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
