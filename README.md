# Kitsune Finance

Kitsune Finance é uma plataforma de gestão financeira pessoal focada em controle, organização e simulação de cenários financeiros.

## Funcionalidades Principais

*   **Painel (Dashboard):** Visão geral unificada do seu patrimônio, receitas, despesas e dívidas mensais.
*   **Gestão de Dívidas:** Controle de parcelamentos e dívidas fixas, com cálculo automático de progresso e impacto mensal.
*   **Simulação Financeira:** Motor de cenários ("e se...") para projetar o impacto de variações de renda ou corte de despesas no seu saldo final.
*   **Orçamentos:** Definição de limites de gastos por categoria.
*   **Metas:** Acompanhamento de objetivos de poupança.

## Como rodar o projeto

1. **Requisitos:** Certifique-se de ter Ruby (versão especificada em `.ruby-version`) e as dependências do sistema instaladas.
2. **Instalação:**
   ```bash
   bundle install
   bin/rails db:prepare
   ```
3. **Execução:**
   ```bash
   ./bin/dev
   ```

## Visão Geral

![Dashboard Kitsune Finance](app/assets/screenshot/dashboard.png)
