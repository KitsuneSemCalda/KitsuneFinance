module InvestmentJson
  extend ActiveSupport::Concern

  private

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
