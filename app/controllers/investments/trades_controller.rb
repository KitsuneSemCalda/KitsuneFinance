class Investments::TradesController < ApplicationController
  include InvestmentJson
  before_action :authenticate_user!
  before_action :set_investment
  layout "dashboard"

  def index
    @trades = @investment.trades.ordered
  end

  def create
    @trade = @investment.trades.new(trade_params)
    @trade.user = current_user

    if @trade.save
      @investment.reload
      respond_to do |format|
        format.html { redirect_to dashboard_investment_trades_path(@investment), notice: "Operação registrada com sucesso." }
        format.json { render json: { investment: investment_json(@investment) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to dashboard_investment_trades_path(@investment), alert: @trade.errors.full_messages.to_sentence }
        format.json { render json: { errors: @trade.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @trade = @investment.trades.find(params[:id])
  end

  def update
    @trade = @investment.trades.find(params[:id])
    if @trade.update(trade_params)
      redirect_to dashboard_investment_trades_path(@investment),
                  notice: "Operação atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trade = @investment.trades.find(params[:id])
    @trade.destroy
    redirect_to dashboard_investment_trades_path(@investment),
                notice: "Operação excluída com sucesso."
  end

  def clear
    @investment.trades.destroy_all
    redirect_to dashboard_investment_trades_path(@investment),
                notice: "Todas as operações foram removidas."
  end

  private

  def set_investment
    @investment = current_user.investments.find(params[:investment_id])
  end

  def trade_params
    params.require(:trade).permit(:trade_type, :quantity, :price, :date, :notes).tap do |p|
      p[:price] = cents_from_string(p[:price]) if p[:price].present?
    end
  end
end
