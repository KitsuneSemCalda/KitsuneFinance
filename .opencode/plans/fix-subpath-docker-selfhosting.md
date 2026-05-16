# Plano: Suporte a Subpath + Docker Self-Hosted

## Problema
O app roda em subpath (ex: `https://dominio.com/kitsune/`) mas não tem suporte a `RAILS_RELATIVE_URL_ROOT`.
Paths hardcoded no JS quebram, rotas não são prefixadas, PWA aponta para lugar errado.

## Passos de Implementação

### 1. Configurar RAILS_RELATIVE_URL_ROOT no Rails

**Arquivo: `config/environments/production.rb`**
- Adicionar após `# config.asset_host`:
```ruby
config.action_controller.relative_url_root = ENV["RAILS_RELATIVE_URL_ROOT"].presence
```

**Arquivo: `config/environments/development.rb`** (opcional, para testes locais)
- Adicionar:
```ruby
config.action_controller.relative_url_root = ENV["RAILS_RELATIVE_URL_ROOT"].presence
```

### 2. Adicionar meta tag base-url nos layouts

**Arquivo: `app/views/layouts/application.html.erb`**
- Adicionar dentro de `<head>`:
```erb
<%= tag.meta name: "kitsune-base-url", content: (Rails.application.config.action_controller.relative_url_root || "") %>
```

**Arquivo: `app/views/layouts/dashboard.html.erb`**
- Adicionar dentro de `<head>` (após linha 11):
```erb
<%= tag.meta name: "kitsune-base-url", content: (Rails.application.config.action_controller.relative_url_root || "") %>
```

### 3. Corrigir paths hardcoded no `kitsune.js`

**Arquivo: `app/javascript/kitsune.js`**

Adicionar helper no início do objeto `Kitsune`:
```javascript
baseUrl() {
  const meta = document.querySelector('meta[name="kitsune-base-url"]')
  return meta ? meta.getAttribute('content') : ''
},
```

Substituir TODOS os paths hardcoded. Locais a modificar:

| Linha | Path | Substituir por |
|-------|------|---------------|
| 164 | `"/dashboard/transactions"` | `` this.baseUrl() + "/dashboard/transactions" `` |
| 312 | `"/dashboard"` | `` this.baseUrl() + "/dashboard" `` |
| 313 | `"/dashboard/transactions"` | `` this.baseUrl() + "/dashboard/transactions" `` |
| 314 | `"/dashboard/accounts"` | `` this.baseUrl() + "/dashboard/accounts" `` |
| 315 | `"/dashboard/budgets"` | `` this.baseUrl() + "/dashboard/budgets" `` |
| 316 | `"/dashboard/goals"` | `` this.baseUrl() + "/dashboard/goals" `` |
| 328 | `'/dashboard'` | `` this.baseUrl() + '/dashboard' `` |
| 352 | `` `/dashboard/transactions/new?duplicate_from=${id}` `` | `` `${this.baseUrl()}/dashboard/transactions/new?duplicate_from=${id}` `` |
| 385 | `"/dashboard/health"` | `` this.baseUrl() + "/dashboard/health" `` |
| 479 | `` `/dashboard/bill_reminders/${id}` `` | `` `${this.baseUrl()}/dashboard/bill_reminders/${id}` `` |
| 567 | `"/dashboard/investments/" + invId` | `` this.baseUrl() + "/dashboard/investments/" + invId `` |
| 662 | `"/dashboard/investments/" + invId + "/trades"` | `` this.baseUrl() + "/dashboard/investments/" + invId + "/trades" `` |
| 724 | `"/dashboard/transactions"` | `` this.baseUrl() + "/dashboard/transactions" `` |
| 728 | `"/dashboard/investments"` | `` this.baseUrl() + "/dashboard/investments" `` |
| 732 | `"/dashboard/accounts"` | `` this.baseUrl() + "/dashboard/accounts" `` |
| 747 | `"/dashboard/transactions?search="` | `` this.baseUrl() + "/dashboard/transactions?search=" `` |

Nas linhas 312-316 (bottomNav), o `baseUrl()` precisa estar acessível. Como o método é chamado via `this.baseUrl()`, precisa ser mantida a referência ao `this`. Alternativa: criar uma variável `const BASE_URL = document.querySelector('meta[name="kitsune-base-url"]')?.getAttribute('content') || ''` no escopo global ou usar `Kitsune.baseUrl()`.

Na linha 328 (bottomNav):
```javascript
currentPath === l.href || ...
```
Como `l.href` será prefixado e `currentPath` também vem prefixado (window.location.pathname), a comparação continua funcionando.

### 4. Corrigir active_check da Carteira na sidebar

**Arquivo: `app/views/layouts/dashboard.html.erb`** (linha 256)

Substituir:
```erb
active_check: -> { current_page?(dashboard_investments_path) || request.path.start_with?('/dashboard/investments') }
```
Por:
```erb
active_check: -> { current_page?(dashboard_investments_path) || request.path.start_with?(dashboard_investments_path) }
```

### 5. Adicionar actions faltantes no CategorizationSuggestionsController

**Arquivo: `app/controllers/categorization_suggestions_controller.rb`**

Adicionar após `def create` e antes de `def destroy`:
```ruby
def show
  @suggestion = current_user.categorization_suggestions.find(params[:id])
  redirect_to edit_dashboard_categorization_suggestion_path(@suggestion)
end

def edit
  @page_title = "Editar Regra"
  @suggestion = current_user.categorization_suggestions.find(params[:id])
end

def update
  @suggestion = current_user.categorization_suggestions.find(params[:id])
  if @suggestion.update(suggestion_params)
    redirect_to dashboard_categorization_suggestions_path, notice: "Regra atualizada com sucesso."
  else
    render :edit, status: :unprocessable_entity
  end
end
```

### 6. Atualizar PWA manifest e service worker

**Arquivo: `app/views/pwa/manifest.json.erb`**

Substituir:
```json
"start_url": "/"
```
Por:
```json
"start_url": "<%= Rails.application.config.action_controller.relative_url_root.presence || '/' %>"
```

E os `src` dos ícones:
```json
"src": "<%= (Rails.application.config.action_controller.relative_url_root.presence || '') + '/icon.svg' %>"
```
```json
"src": "<%= (Rails.application.config.action_controller.relative_url_root.presence || '') + '/icon.png' %>"
```

**Arquivo: `app/views/pwa/service_worker.js.erb`**

Substituir paths hardcoded por paths dinâmicos:
```javascript
const BASE_PATH = '<%= Rails.application.config.action_controller.relative_url_root.presence || "" %>';
const ASSETS_TO_CACHE = [
  BASE_PATH + '/',
  BASE_PATH + '/icon.svg'
];
```

### 7. Docker para produção

**Arquivo: `Dockerfile`** (linha 6 - comentário)
Substituir:
```
-v ~/.local/share/KitsuneFinance:/rails/data
```
Por:
```
-v ~/.local/share/KitsuneFinance:/rails/storage
```

**Arquivo: `docker-compose.yml`** — Criar `docker-compose.prod.yml`:
```yaml
services:
  web:
    build: .
    image: kitsune_finance:latest
    ports:
      - "13522:80"
    environment:
      - RAILS_ENV=production
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - RAILS_RELATIVE_URL_ROOT=${RAILS_RELATIVE_URL_ROOT:-}
      - APP_HOST=${APP_HOST:-localhost}
    volumes:
      - kitsune_data:/rails/storage
    restart: unless-stopped

volumes:
  kitsune_data:
```

**Arquivo: `bin/docker-build`** — Adicionar passagem de env vars:
```bash
docker run -d --name kitsune_finance -p 13522:80 \
  -v "$(pwd)/storage:/rails/storage" \
  -e RAILS_ENV=production \
  -e RAILS_RELATIVE_URL_ROOT="${RAILS_RELATIVE_URL_ROOT:-}" \
  --restart unless-stopped \
  kitsune_finance:latest
```

## Verificação

1. Rodar `bin/rails routes` para confirmar que nada quebrou
2. Rodar `bin/rails tailwindcss:build` para rebuildar CSS
3. Verificar se o app sobe sem erros
4. Testar acesso via subpath
5. Verificar se a sidebar destaca o link correto
