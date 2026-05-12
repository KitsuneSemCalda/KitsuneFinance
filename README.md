# Kitsune Finance

Kitsune Finance é uma plataforma de gestão financeira pessoal focada em controle, organização e simulação de cenários financeiros.

## Funcionalidades Principais

* **Painel (Dashboard):** Visão geral unificada do seu patrimônio, receitas, despesas e dívidas mensais.
* **Gestão de Dívidas:** Controle de parcelamentos e dívidas fixas, com cálculo automático de progresso e impacto mensal.
* **Simulação Financeira:** Motor de cenários ("e se...") para projetar o impacto de variações de renda ou corte de despesas no seu saldo final.
* **Orçamentos:** Definição de limites de gastos por categoria.
* **Metas:** Acompanhamento de objetivos de poupança.

## Como rodar o projeto

A forma oficial de rodar o Kitsune Finance é utilizando Docker.

1. **Build da imagem:**

   ```bash
   ./bin/docker-build
   ```

2. **Execução:**

   ```bash
   docker run -d --name kitsune_finance -p 13522:80 \
     -v ~/.local/share/KitsuneFinance:/rails/storage \
     --restart unless-stopped \
     kitsune_finance:latest
   ```

## Visão Geral

![Dashboard Kitsune Finance](https://github.com/KitsuneSemCalda/KitsuneFinance/blob/master/assets/screenshot/dashboard.png?raw=true)
