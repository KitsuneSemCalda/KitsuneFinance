# Default Categories Seed
categories = [
  { name: "Salário", transaction_type: "income", color: "emerald", icon: "💰" },
  { name: "Investimentos", transaction_type: "income", color: "indigo", icon: "📈" },
  { name: "Alimentação", transaction_type: "expense", color: "amber", icon: "🍔" },
  { name: "Transporte", transaction_type: "expense", color: "sky", icon: "🚕" },
  { name: "Moradia", transaction_type: "expense", color: "zinc", icon: "🏠" },
  { name: "Lazer", transaction_type: "expense", color: "purple", icon: "🎮" },
  { name: "Saúde", transaction_type: "expense", color: "rose", icon: "💊" },
  { name: "Educação", transaction_type: "expense", color: "indigo", icon: "📚" }
]

User.find_each do |user|
  categories.each do |cat|
    user.categories.find_or_create_by!(name: cat[:name]) do |c|
      c.transaction_type = cat[:transaction_type]
      c.color = cat[:color]
      c.icon = cat[:icon]
    end
  end
end

# Sample accounts for demo users
if Rails.env.development? && (demo = User.first)
  unless demo.accounts.any?
    checking = demo.accounts.create!(name: "Conta Corrente", account_type: "checking", balance: 150_00, color: "indigo", icon: "🏦")
    savings = demo.accounts.create!(name: "Poupança", account_type: "savings", balance: 500_00, color: "emerald", icon: "🐷")
    cash = demo.accounts.create!(name: "Carteira", account_type: "cash", balance: 3_50, color: "amber", icon: "👛")

    income_cat = demo.categories.find_by(transaction_type: "income")
    expense_cat = demo.categories.find_by(transaction_type: "expense", name: "Alimentação")

    demo.transactions.create!(account: checking, category: income_cat, description: "Salário Maio/2026", amount: 5000_00, transaction_type: "income", date: Date.new(2026, 5, 5))
    demo.transactions.create!(account: checking, category: expense_cat, description: "Supermercado", amount: 2_50, transaction_type: "expense", date: Date.new(2026, 5, 6))
    demo.transactions.create!(account: checking, description: "Aluguel", amount: 1200_00, transaction_type: "expense", date: Date.new(2026, 5, 1))

    demo.goals.create!(name: "Reserva de Emergência", target_amount: 15000_00, current_amount: 5000_00, deadline: 1.year.from_now, icon: "🛡️", color: "emerald")
    demo.goals.create!(name: "Viagem dos Sonhos", target_amount: 8000_00, current_amount: 1500_00, deadline: 6.months.from_now, icon: "✈️", color: "sky")
  end
end
