class DebtsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_debt, only: [:edit, :update, :destroy]
  layout "dashboard"

  def index
    @debts = current_user.debts
  end

  def new
    @debt = current_user.debts.new
  end

  def create
    params[:debt][:total_amount] = (params[:debt][:total_amount].to_f * 100).to_i if params[:debt][:total_amount].present?
    params[:debt][:monthly_payment] = (params[:debt][:monthly_payment].to_f * 100).to_i if params[:debt][:monthly_payment].present?
    @debt = current_user.debts.new(debt_params)
    if @debt.save
      redirect_to dashboard_debts_path, notice: "Dívida cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    params[:debt][:total_amount] = (params[:debt][:total_amount].to_f * 100).to_i if params[:debt][:total_amount].present?
    params[:debt][:monthly_payment] = (params[:debt][:monthly_payment].to_f * 100).to_i if params[:debt][:monthly_payment].present?
    if @debt.update(debt_params)
      redirect_to dashboard_debts_path, notice: "Dívida atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @debt.destroy
    redirect_to dashboard_debts_path, notice: "Dívida removida."
  end

  private

  def set_debt
    @debt = current_user.debts.find(params[:id])
  end

  def debt_params
    params.require(:debt).permit(:name, :total_amount, :monthly_payment, :installments_count, :remaining_installments)
  end
end
