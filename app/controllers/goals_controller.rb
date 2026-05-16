class GoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_goal, only: %i[edit update destroy contribute]
  layout "dashboard"

  def index
    @page_title = "Metas"
    @goals = current_user.goals
    @accounts = current_user.accounts

    respond_to do |format|
      format.html
      format.any(:csv) { send_data generate_csv(@goals), filename: "metas-#{Date.today}.csv" }
      format.any(:xlsx) { response.headers["Content-Disposition"] = "attachment; filename=\"metas-#{Date.today}.xlsx\"" }
    end
  end

  def new
    @page_title = "Nova Meta"
    @goal = current_user.goals.new
  end

  def create
    convert_to_cents(:target_amount, :current_amount)
    @goal = current_user.goals.new(goal_params)
    if @goal.save
      redirect_to dashboard_goals_path, notice: "Meta criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    convert_to_cents(:target_amount, :current_amount)
    if @goal.update(goal_params)
      redirect_to dashboard_goals_path, notice: "Meta atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    redirect_to dashboard_goals_path, notice: "Meta excluída com sucesso."
  end

  def contribute
    amount = params[:amount].to_i
    account = current_user.accounts.find_by(id: params[:account_id]) || current_user.accounts.first

    if amount > 0 && account
      transaction = current_user.transactions.new(
        account: account,
        goal: @goal,
        amount: amount,
        transaction_type: "expense",
        description: "Contribuição para meta: #{@goal.name}",
        date: Date.today
      )

      if transaction.save
        redirect_to dashboard_goals_path, notice: "Contribuição registrada com sucesso."
      else
        redirect_to dashboard_goals_path, alert: "Erro ao registrar contribuição: #{transaction.errors.full_messages.join(', ')}"
      end
    else
      redirect_to dashboard_goals_path, alert: "Valor ou conta inválida."
    end
  end

  private

  def set_goal
    @goal = current_user.goals.find(params[:id])
  end

  def generate_csv(goals)
    CSV.generate(headers: true, col_sep: ";") do |csv|
      csv << [ "Nome", "Objetivo", "Atual", "Progresso", "Prazo", "Status" ]
      goals.each do |goal|
        csv << [ goal.name, goal.target_amount, goal.current_amount, "#{goal.progress_pct}%", goal.deadline, goal.status ]
      end
    end
  end

  def goal_params
    params.require(:goal).permit(:name, :icon, :target_amount, :current_amount, :deadline, :color, :status, :notes)
  end
end
