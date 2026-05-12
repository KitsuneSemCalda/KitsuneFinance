class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: %i[edit update destroy]
  layout "dashboard"

  def index
    @page_title = "Contas"
    @accounts = current_user.accounts

    respond_to do |format|
      format.html
      format.json { render json: @accounts.select(:id, :name, :account_type, :balance, :currency) }
    end
  end

  def new
    @page_title = "Nova Conta"
    @account = current_user.accounts.new
  end

  def create
    params[:account][:balance] = (params[:account][:balance].to_f * 100).to_i if params[:account][:balance].present?
    @account = current_user.accounts.new(account_params)
    if @account.save
      redirect_to dashboard_accounts_path, notice: "Conta criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page_title = "Editar Conta"
  end

  def update
    params[:account][:balance] = (params[:account][:balance].to_f * 100).to_i if params[:account][:balance].present?
    if @account.update(account_params)
      redirect_to dashboard_accounts_path, notice: "Conta atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    redirect_to dashboard_accounts_path, notice: "Conta excluída com sucesso."
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:name, :account_type, :balance, :currency, :color, :icon)
  end
end
