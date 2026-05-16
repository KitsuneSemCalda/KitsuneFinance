class InsightService
  def self.generate(user)
    insights = []
    
    current_month = Date.today.beginning_of_month
    three_months_ago = 3.months.ago.beginning_of_month
    
    current_expenses = user.transactions.expense.where(date: current_month..Date.today).sum(:amount)
    past_expenses = user.transactions.expense.where(date: three_months_ago..current_month.yesterday).sum(:amount) / 3.0
    
    if past_expenses > 0
      diff = ((current_expenses - past_expenses) / past_expenses) * 100
      if diff > 10
        insights << { 
          title: "Atenção aos Gastos", 
          message: "Seus gastos estão #{diff.round}% acima da média dos últimos 3 meses.", 
          type: "warning" 
        }
      elsif diff < -10
        insights << { 
          title: "Parabéns!", 
          message: "Você reduziu seus gastos em #{diff.abs.round}% comparado à média recente.", 
          type: "success" 
        }
      end
    end

    top_category = user.transactions.expense.where(date: current_month..Date.today)
                      .joins(:category)
                      .group("categories.name")
                      .order("SUM(transactions.amount) DESC")
                      .limit(1)
                      .sum(:amount)
                      .first

    if top_category
      insights << {
        title: "Categoria em Destaque",
        message: "Sua maior despesa este mês é em '#{top_category[0]}' com R$ #{(top_category[1]/100.0).round(2)}.",
        type: "info"
      }
    end

    insights
  end
end
