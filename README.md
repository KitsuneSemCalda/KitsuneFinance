# Kitsune Finance

Kitsune Finance é uma plataforma de gestão financeira pessoal focada em controle, organização e simulação de cenários financeiros.

## Funcionalidades Principais

* **Painel (Dashboard):** Visão geral unificada do seu patrimônio, receitas, despesas e dívidas mensais.
* **Gestão de Dívidas:** Controle de parcelamentos e dívidas fixas, com cálculo automático de progresso e impacto mensal.
* **Simulação Financeira:** Motor de cenários ("e se...") para projetar o impacto de variações de renda ou corte de despesas no seu saldo final.
* **Orçamentos:** Definição de limites de gastos por categoria.
* **Metas:** Acompanhamento de objetivos de poupança.

## Como rodar o projeto

A forma recomendada de rodar o Kitsune Finance é utilizando Docker Compose.

### 1. Preparação

Crie um arquivo `.env` com as configurações básicas (opcional):
```bash
RAILS_MASTER_KEY=sua_chave_mestra # Ou use SECRET_KEY_BASE
RAILS_RELATIVE_URL_ROOT=/kitsune   # Se for rodar em subpath
```

### 2. Execução

Para rodar em modo produção (auto-hospedagem):

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

O sistema estará disponível em `http://localhost:13522`.

### 3. Scripts Utilitários

- `./bin/docker-build --prod`: Atalho para buildar e iniciar em produção.
- `./bin/docker-dev`: Para ambiente de desenvolvimento.

## Visão Geral

![Dashboard Kitsune Finance](https://github.com/KitsuneSemCalda/KitsuneFinance/blob/master/assets/screenshot/dashboard.png?raw=true)
