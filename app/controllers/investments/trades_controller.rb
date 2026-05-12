class Investments::TradesController < ApplicationController
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
      p[:price] = (p[:price].to_f * 100).to_i if p[:price].present?
    end
  end

  def investment_json(inv)
    {
      id: inv.id,
      quantity: inv.quantity,
      avg_price: inv.avg_price,
      current_price: inv.current_price,
      current_value: inv.current_value,
      total_cost: inv.total_cost,
      gain_loss: inv.gain_loss,
      gain_loss_pct: inv.gain_loss_pct
    }
  end
end
