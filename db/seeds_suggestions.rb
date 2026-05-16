
keywords = {
  "IFOOD" => "Alimentação",
  "RAPPID" => "Alimentação",
  "UBER" => "Transporte",
  "99APP" => "Transporte",
  "NETFLIX" => "Lazer",
  "SPOTIFY" => "Lazer",
  "AMAZON" => "Compras",
  "MERCADO LIVRE" => "Compras",
  "MAGALU" => "Compras",
  "MERCADO" => "Alimentação",
  "CARREFOUR" => "Alimentação",
  "PÃO DE AÇUCAR" => "Alimentação",
  "POSTO" => "Transporte",
  "SHELL" => "Transporte",
  "IPIRANGA" => "Transporte",
  "FARMACIA" => "Saúde",
  "DROGASIL" => "Saúde",
  "RAIA" => "Saúde",
  "CONDOMINIO" => "Moradia",
  "ALUGUEL" => "Moradia",
  "ENEL" => "Contas Fixas",
  "SABESP" => "Contas Fixas",
  "VIVO" => "Contas Fixas",
  "CLARO" => "Contas Fixas"
}

User.find_each do |user|
  keywords.each do |keyword, category_name|
    category = user.categories.find_or_create_by!(name: category_name, transaction_type: "expense")
    user.categorization_suggestions.find_or_create_by!(keyword: keyword, category: category)
  end
end
