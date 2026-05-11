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
