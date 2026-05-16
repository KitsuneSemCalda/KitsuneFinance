import jQuery from "jquery"

const $ = jQuery
window.$ = window.jQuery = $

$(document).on("turbo:load", function () {
  Kitsune.init()
})

const Kitsune = {
  init() {
    this.quickTransaction()
    this.transactionFilters()
    this.duplicateTransaction()
    this.keyboardShortcuts()
    this.bottomNav()
    this.dashboardCustomizer()
    this.themeToggle()
    this.billReminderCheckboxes()
    this.receiptPreview()
    this.toggleRecurrence()
    this.toggleInstallment()
    this.quickTrade()
    this.transferFormToggle()
    this.formLoadingStates()
  },

  // Helper para checar elementos
  ensure(selector, callback) {
    const el = document.querySelector(selector)
    if (el) callback(el)
  },

  // ──────────────────────────────────────────────
  // 1. QUICK TRANSACTION — Botão flutuante + Modal
  // ──────────────────────────────────────────────
  quickTransaction() {
    if ($("#quick-tx-btn").length) return

    const btn = $(
      `<button id="quick-tx-btn"
         class="fixed bottom-6 right-6 z-50 w-14 h-14 rounded-full
                bg-gradient-to-br from-indigo-500 to-violet-600
                shadow-2xl shadow-indigo-500/40
                flex items-center justify-center
                hover:scale-110 active:scale-95
                transition-all duration-200
                lg:bottom-8 lg:right-8"
         aria-label="Nova Transação Rápida">
        <svg class="w-7 h-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
        </svg>
      </button>`
    )
    
    btn.on('click', () => this.openQuickTxModal())
    $("body").append(btn)
    
    // ... modal setup remains similar but ensure modal exists/is unique
  },

    const modal = $(`
      <div id="quick-tx-modal"
           class="fixed inset-0 z-[60] hidden items-center justify-center
                  bg-black/60 backdrop-blur-sm transition-opacity"
           onclick="if(event.target===this) Kitsune.closeQuickTxModal()">
        <div class="bg-zinc-900 border border-zinc-800 rounded-3xl shadow-2xl
                    w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto
                    animate-fade-in-up">
          <div class="flex items-center justify-between px-6 py-4 border-b border-zinc-800">
            <h3 class="text-sm font-bold text-zinc-100">Nova Transação</h3>
            <button onclick="Kitsune.closeQuickTxModal()"
                    class="text-zinc-500 hover:text-zinc-300 p-1 rounded-lg hover:bg-zinc-800 transition-colors">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>
          <form id="quick-tx-form" class="p-6 space-y-4">
            <input type="hidden" name="authenticity_token" value="${$('meta[name=csrf-token]').attr('content')}">

            <div class="flex bg-zinc-800 p-1 rounded-xl">
              <label class="flex-1 cursor-pointer">
                <input type="radio" name="transaction[transaction_type]" value="expense" checked class="peer sr-only">
                <div class="py-2 text-center text-xs font-bold uppercase tracking-wider rounded-lg peer-checked:bg-red-500/20 peer-checked:text-red-400 text-zinc-500 transition-all">Despesa</div>
              </label>
              <label class="flex-1 cursor-pointer">
                <input type="radio" name="transaction[transaction_type]" value="income" class="peer sr-only">
                <div class="py-2 text-center text-xs font-bold uppercase tracking-wider rounded-lg peer-checked:bg-emerald-500/20 peer-checked:text-emerald-400 text-zinc-500 transition-all">Receita</div>
              </label>
            </div>

            <div>
              <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Valor (R$)</label>
              <input type="number" name="transaction[amount]" step="0.01" required
                     class="w-full mt-1 bg-zinc-800 border border-zinc-700 rounded-xl px-4 py-3 text-lg font-bold text-zinc-100 focus:border-indigo-500 outline-none transition-all"
                     placeholder="0,00">
            </div>

            <div>
              <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Descrição</label>
              <input type="text" name="transaction[description]" required
                     class="w-full mt-1 bg-zinc-800 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-zinc-100 focus:border-indigo-500 outline-none transition-all"
                     placeholder="Ex: Supermercado, Aluguel...">
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Conta</label>
                <select name="transaction[account_id]" required
                        class="w-full mt-1 bg-zinc-800 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-zinc-100 focus:border-indigo-500 outline-none transition-all">
                  <option value="">Selecione</option>
                </select>
              </div>
              <div>
                <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Categoria</label>
                <select name="transaction[category_id]"
                        class="w-full mt-1 bg-zinc-800 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-zinc-100 focus:border-indigo-500 outline-none transition-all">
                  <option value="">Sem categoria</option>
                </select>
              </div>
            </div>

            <div>
              <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Data</label>
              <input type="date" name="transaction[date]" value="${new Date().toISOString().split('T')[0]}"
                     class="w-full mt-1 bg-zinc-800 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-zinc-100 focus:border-indigo-500 outline-none transition-all">
            </div>

            <button type="submit"
                    class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-bold py-3.5 rounded-xl transition-all shadow-lg shadow-indigo-500/25 text-sm uppercase tracking-widest">
              Registrar
            </button>
          </form>
        </div>
      </div>
    `)

    $("body").append(modal)

    $.get("/dashboard/accounts.json", function (accounts) {
      const sel = modal.find('select[name="transaction[account_id]"]')
      accounts.forEach(function (a) {
        sel.append(`<option value="${a.id}">${a.name}</option>`)
      })
    })

    $.get("/dashboard/categories.json", function (categories) {
      const sel = modal.find('select[name="transaction[category_id]"]')
      categories.forEach(function (c) {
        sel.append(`<option value="${c.id}">${c.icon} ${c.name}</option>`)
      })
    })

    modal.find("#quick-tx-form").on("submit", function (e) {
      e.preventDefault()
      const form = $(this)
      const btn = form.find("button[type=submit]")
      btn.text("Salvando...").prop("disabled", true)

      const data = form.serialize()

      $.ajax({
        url: "/dashboard/transactions",
        method: "POST",
        data: data,
        success() {
          Kitsune.closeQuickTxModal()
          Kitsune.showToast("Transação registrada com sucesso!", "success")
          setTimeout(() => window.location.reload(), 800)
        },
        error(xhr) {
          const err = xhr.responseJSON?.error || "Erro ao registrar transação"
          btn.text("Registrar").prop("disabled", false)
          Kitsune.showToast(err, "error")
        }
      })
    })
  },

  openQuickTxModal() {
    $("#quick-tx-modal").removeClass("hidden").addClass("flex")
  },

  closeQuickTxModal() {
    $("#quick-tx-modal").addClass("hidden").removeClass("flex")
    $("#quick-tx-form")[0]?.reset()
  },

  // ──────────────────────────────────────────────
  // 2. BUSCA E FILTROS — Transações
  // ──────────────────────────────────────────────
  transactionFilters() {
    if (!$("#tx-search").length) return

    let debounceTimer

    $("#tx-search").on("input", function () {
      clearTimeout(debounceTimer)
      const q = $(this).val()
      debounceTimer = setTimeout(() => Kitsune.filterTransactions(), 300)
    })

    $("#tx-filter-type, #tx-filter-category, #tx-filter-account").on("change", function () {
      Kitsune.filterTransactions()
    })

    $("#tx-date-range").on("change", function () {
      const val = $(this).val()
      const custom = $("#tx-date-custom")
      if (val === "custom") {
        custom.removeClass("hidden")
      } else {
        custom.addClass("hidden")
        Kitsune.filterTransactions()
      }
    })

    $("#tx-date-from, #tx-date-to").on("change", function () {
      Kitsune.filterTransactions()
    })

    $("#tx-filter-reset").on("click", function () {
      $("#tx-search").val("")
      $("#tx-filter-type").val("")
      $("#tx-filter-category").val("")
      $("#tx-filter-account").val("")
      $("#tx-date-range").val("")
      $("#tx-date-custom").addClass("hidden")
      $("#tx-date-from").val("")
      $("#tx-date-to").val("")
      Kitsune.filterTransactions()
    })
  },

  filterTransactions() {
    const q = ($("#tx-search").val() || "").toLowerCase()
    const type = $("#tx-filter-type").val()
    const category = $("#tx-filter-category").val()
    const account = $("#tx-filter-account").val()
    const dateRange = $("#tx-date-range").val()

    const rows = $(".tx-row, .tx-mobile-card")
    let visibleCount = 0

    rows.each(function () {
      const row = $(this)
      const desc = row.data("description")?.toLowerCase() || ""
      const rowType = row.data("type") || ""
      const rowCat = row.data("category") || ""
      const rowAcc = row.data("account") || ""
      const rowDate = row.data("date") || ""

      let show = true
      if (q && !desc.includes(q)) show = false
      if (type && rowType !== type) show = false
      if (category && rowCat !== category) show = false
      if (account && rowAcc !== account) show = false

      if (dateRange && dateRange !== "all") {
        const today = new Date()
        let from, to
        switch (dateRange) {
          case "today":
            from = to = today.toISOString().split("T")[0]
            break
          case "week":
            from = new Date(today.setDate(today.getDate() - today.getDay())).toISOString().split("T")[0]
            to = new Date().toISOString().split("T")[0]
            break
          case "month":
            from = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().split("T")[0]
            to = new Date().toISOString().split("T")[0]
            break
          case "custom":
            from = $("#tx-date-from").val()
            to = $("#tx-date-to").val()
            break
        }
        if (from && to) {
          if (rowDate < from || rowDate > to) show = false
        }
      }

      row.toggle(show)
      if (show) visibleCount++
    })

    const emptyMsg = $("#tx-empty-filter")
    if (visibleCount === 0) {
      if (!emptyMsg.length) {
        $(".tx-table-wrapper, .tx-mobile-wrapper").after(
          `<div id="tx-empty-filter" class="text-center py-12">
            <p class="text-zinc-500 text-sm">Nenhuma transação encontrada para os filtros aplicados.</p>
          </div>`
        )
      }
      emptyMsg.show()
    } else {
      emptyMsg.hide()
    }
  },

  // ──────────────────────────────────────────────
  // 3. BOTTOM NAV MOBILE
  // ──────────────────────────────────────────────
  bottomNav() {
    if ($("#bottom-nav").length) return

    const currentPath = window.location.pathname
    const links = [
      { href: "/dashboard", icon: "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6", label: "Visão Geral" },
      { href: "/dashboard/transactions", icon: "M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4", label: "Transações" },
      { href: "/dashboard/accounts", icon: "M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z", label: "Contas" },
      { href: "/dashboard/budgets", icon: "M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z", label: "Orçamento" },
      { href: "/dashboard/goals", icon: "M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z", label: "Metas" }
    ]

    const nav = $(
      `<nav id="bottom-nav"
            class="fixed bottom-0 left-0 right-0 z-40 lg:hidden
                   bg-zinc-900/95 border-t border-zinc-800/60 backdrop-blur-xl
                   safe-area-bottom">
        <div class="flex items-center justify-around px-2 py-1">
          ${links.map(l => `
            <a href="${l.href}"
               class="flex flex-col items-center gap-0.5 px-3 py-2 rounded-xl transition-all
                      ${currentPath === l.href || currentPath.startsWith(l.href + '/') || (l.href === '/dashboard' && currentPath === '/dashboard')
                        ? 'text-indigo-400'
                        : 'text-zinc-500 hover:text-zinc-300'}">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                <path stroke-linecap="round" stroke-linejoin="round" d="${l.icon}"/>
              </svg>
              <span class="text-[9px] font-bold uppercase tracking-wider">${l.label}</span>
            </a>
          `).join("")}
        </div>
      </nav>`
    )

    $("body").append(nav)
    $("main").css("padding-bottom", "72px")
  },

  // ──────────────────────────────────────────────
  // 4. DUPLICAR TRANSAÇÃO
  // ──────────────────────────────────────────────
  duplicateTransaction() {
    $(document).on("click", ".tx-duplicate-btn", function () {
      const tx = $(this).closest("[data-tx-id]")
      const id = tx.data("tx-id")
      window.location.href = `/dashboard/transactions/new?duplicate_from=${id}`
    })
  },

  // ──────────────────────────────────────────────
  // 5. ATALHOS DE TECLADO
  // ──────────────────────────────────────────────
  keyboardShortcuts() {
    $(document).off("keydown.kitsune").on("keydown.kitsune", function (e) {
      if ($(e.target).is("input, textarea, select, [contenteditable]")) return

      if ((e.ctrlKey || e.metaKey) && e.key === "b") {
        e.preventDefault()
        if (typeof toggleSidebar === "function") toggleSidebar()
        return
      }

      switch (e.key.toLowerCase()) {
        case "n":
          e.preventDefault()
          Kitsune.openQuickTxModal()
          break
        case "escape":
          Kitsune.closeQuickTxModal()
          Kitsune.closeSearchModal()
          $("#tx-filter-dropdown").addClass("hidden")
          break
        case "/":
          e.preventDefault()
          $("#tx-search").focus()
          break
        case "h":
          if (e.ctrlKey || e.metaKey) break
          window.location.href = "/dashboard/health"
          break
      }
    })
  },

  // ──────────────────────────────────────────────
  // 6. DASHBOARD CUSTOMIZER
  // ──────────────────────────────────────────────
  dashboardCustomizer() {
    if (!$("#dashboard-customizer").length) return

    const prefs = Kitsune.getDashboardPrefs()

    $(".dashboard-widget").each(function () {
      const id = $(this).attr("id")
      if (prefs && !prefs[id]) $(this).hide()
    })

    $(".dash-toggle").on("change", function () {
      const id = $(this).data("widget")
      const checked = $(this).prop("checked")
      const prefs = Kitsune.getDashboardPrefs() || {}
      prefs[id] = checked
      localStorage.setItem("kitsune_dashboard_prefs", JSON.stringify(prefs))
      if (checked) {
        $("#" + id).slideDown(300)
      } else {
        $("#" + id).slideUp(300)
      }
    })
  },

  getDashboardPrefs() {
    try {
      return JSON.parse(localStorage.getItem("kitsune_dashboard_prefs"))
    } catch {
      return null
    }
  },

  // ──────────────────────────────────────────────
  // 7. THEME TOGGLE (Light/Dark)
  // ──────────────────────────────────────────────
  themeToggle() {
    const theme = localStorage.getItem("kitsune_theme") || "dark"
    if (theme === "light") Kitsune.applyLightTheme()

    $(document).on("click", "#theme-toggle-btn", function () {
      const isDark = !$("html").hasClass("light-theme")
      if (isDark) {
        Kitsune.applyLightTheme()
        localStorage.setItem("kitsune_theme", "light")
      } else {
        Kitsune.applyDarkTheme()
        localStorage.setItem("kitsune_theme", "dark")
      }
    })
  },

  applyLightTheme() {
    $("html").addClass("light-theme")
    $("body").css({
      "background-color": "#fafafa",
      color: "#18181b"
    })
    $("#theme-toggle-btn").html(`
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
      </svg>
    `)
  },

  applyDarkTheme() {
    $("html").removeClass("light-theme")
    $("body").css({
      "background-color": "#09090b",
      color: "#f4f4f5"
    })
    $("#theme-toggle-btn").html(`
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>
      </svg>
    `)
  },

  // ──────────────────────────────────────────────
  // 8. BILL REMINDERS — Checkbox toggle
  // ──────────────────────────────────────────────
  billReminderCheckboxes() {
    $(document).on("change", ".bill-paid-checkbox", function () {
      const id = $(this).data("bill-id")
      const paid = $(this).prop("checked")
      $.ajax({
        url: `/dashboard/bill_reminders/${id}`,
        method: "PATCH",
        data: { bill_reminder: { paid: paid } },
        success() {
          $(`.bill-row-${id}`).toggleClass("opacity-50 line-through", paid)
        }
      })
    })
  },

  // ──────────────────────────────────────────────
  // 9. RECEIPT PREVIEW
  // ──────────────────────────────────────────────
  receiptPreview() {
    $(document).on("change", "#transaction_receipt", function () {
      const file = this.files[0]
      if (!file) return
      const reader = new FileReader()
      reader.onload = function (e) {
        const preview = $("#receipt-preview")
        if (!preview.length) {
          $(`<div id="receipt-preview" class="mt-2">
               <img src="${e.target.result}" class="max-h-32 rounded-xl border border-zinc-700">
             </div>`).insertAfter("#transaction_receipt")
        } else {
          preview.find("img").attr("src", e.target.result)
        }
      }
      reader.readAsDataURL(file)
    })
  },

  // ──────────────────────────────────────────────
  // 9B. TOGGLE RECURRENCE PERIOD
  // ──────────────────────────────────────────────
  toggleRecurrence() {
    $(document).on("change", "#transaction_recurrent", function () {
      $("#recurrence-period-field").toggleClass("hidden", !this.checked)
    })
  },

  // ──────────────────────────────────────────────
  // 9C. TOGGLE INSTALLMENT FIELDS
  // ──────────────────────────────────────────────
  toggleInstallment() {
    $(document).on("change", "#transaction_installment", function () {
      $("#installment-fields").toggleClass("hidden", !this.checked)
    })
  },

  // ──────────────────────────────────────────────
  // 10. INVESTMENTS — Inline Editing
  // ──────────────────────────────────────────────
  inlineEditInvestments() {
    $(document).on("click", ".inline-edit", function () {
      const cell = $(this)
      if (cell.find("input").length) return

      const invId = cell.data("investment-id")
      const field = cell.data("field")
      const isCurrency = cell.data("currency") || false
      const rawValue = cell.data("value")

      const input = $(`<input type="number" step="any"
        class="w-24 bg-zinc-800 border border-indigo-500 rounded-lg px-2 py-1 text-right text-sm text-zinc-100"
        value="${rawValue}">`)

      cell.empty().append(input)
      input.focus().select()

      function revert() {
        const display = isCurrency
          ? "R$ " + parseFloat(rawValue).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 4 })
          : parseFloat(rawValue).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 4 })
        cell.text(display).data("value", rawValue)
      }

      function save() {
        const newVal = input.val()
        if (!newVal || parseFloat(newVal) === parseFloat(rawValue)) {
          revert()
          return
        }

        const data = { investment: {} }
        data.investment[field] = newVal

        $.ajax({
          url: "/dashboard/investments/" + invId,
          method: "PATCH",
          data: data,
          success(resp) {
            Kitsune.updateInvestmentRow(resp.investment)
            Kitsune.showToast("Atualizado!", "success")
          },
          error(xhr) {
            revert()
            const err = xhr.responseJSON?.errors?.join(", ") || "Erro ao atualizar"
            Kitsune.showToast(err, "error")
          }
        })
      }

      input.on("blur", save)
      input.on("keydown", function (e) {
        if (e.key === "Enter") { e.preventDefault(); input.blur() }
        if (e.key === "Escape") { e.preventDefault(); revert() }
      })
    })
  },

  // ──────────────────────────────────────────────
  // 11. INVESTMENTS — Quick Trade (Comprar/Vender)
  // ──────────────────────────────────────────────
  quickTrade() {
    $(document).on("click", ".quick-trade-btn", function () {
      const invId = $(this).data("investment-id")
      const ticker = $(this).data("ticker")
      const tradeType = $(this).data("trade-type")

      const modalId = "quick-trade-modal"
      $("#" + modalId).remove()

      const modal = $(`
        <div id="${modalId}"
             class="fixed inset-0 z-[60] hidden items-center justify-center bg-black/60 backdrop-blur-sm transition-opacity"
             onclick="if(event.target===this) Kitsune.closeQuickTradeModal()">
          <div class="bg-zinc-900 border border-zinc-800 rounded-3xl shadow-2xl w-full max-w-sm mx-4 animate-fade-in-up">
            <div class="flex items-center justify-between px-6 py-4 border-b border-zinc-800">
              <h3 class="text-sm font-bold text-zinc-100">
                ${tradeType === "buy" ? "Comprar" : "Vender"} — ${ticker}
              </h3>
              <button onclick="Kitsune.closeQuickTradeModal()"
                      class="text-zinc-500 hover:text-zinc-300 p-1 rounded-lg hover:bg-zinc-800 transition-colors">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </div>
            <form class="p-6 space-y-4">
              <input type="hidden" name="authenticity_token" value="${$("meta[name=csrf-token]").attr("content")}">
              <input type="hidden" name="trade[trade_type]" value="${tradeType}">

              <div class="grid grid-cols-2 gap-3">
                <div>
                  <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Quantidade</label>
                  <input type="number" name="trade[quantity]" step="any" required
                         class="w-full mt-1 bg-zinc-800 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-zinc-100 focus:border-indigo-500 outline-none transition-all"
                         placeholder="Ex: 100">
                </div>
                <div>
                  <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Preço (R$)</label>
                  <input type="number" name="trade[price]" step="0.01" required
                         class="w-full mt-1 bg-zinc-800 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-zinc-100 focus:border-indigo-500 outline-none transition-all"
                         placeholder="Ex: 35,50">
                </div>
              </div>

              <div>
                <label class="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Data</label>
                <input type="date" name="trade[date]" value="${new Date().toISOString().split("T")[0]}"
                       class="w-full mt-1 bg-zinc-800 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-zinc-100 focus:border-indigo-500 outline-none transition-all">
              </div>

              <button type="submit"
                      class="w-full ${tradeType === "buy" ? "bg-emerald-600 hover:bg-emerald-500" : "bg-red-600 hover:bg-red-500"} text-white font-bold py-3.5 rounded-xl transition-all shadow-lg text-sm uppercase tracking-widest">
                ${tradeType === "buy" ? "Comprar" : "Vender"}
              </button>
            </form>
          </div>
        </div>
      `)

      $("body").append(modal)
      modal.removeClass("hidden").addClass("flex")

      modal.find("form").on("submit", function (e) {
        e.preventDefault()
        const form = $(this)
        const btn = form.find("button[type=submit]")
        btn.text("Salvando...").prop("disabled", true)

        $.ajax({
          url: "/dashboard/investments/" + invId + "/trades",
          method: "POST",
          data: form.serialize(),
          success(resp) {
            Kitsune.closeQuickTradeModal()
            Kitsune.updateInvestmentRow(resp.investment)
            Kitsune.showToast("Operação registrada!", "success")
          },
          error(xhr) {
            const err = xhr.responseJSON?.errors?.join(", ") || "Erro ao registrar operação"
            btn.text(tradeType === "buy" ? "Comprar" : "Vender").prop("disabled", false)
            Kitsune.showToast(err, "error")
          }
        })
      })
    })
  },

  closeQuickTradeModal() {
    $("#quick-trade-modal").addClass("hidden").removeClass("flex")
  },

  // ──────────────────────────────────────────────
  // 12B. TRANSFER FORM — Toggle destination account
  // ──────────────────────────────────────────────
  transferFormToggle() {
    const destField = $("#destination-account-field")
    if (!destField.length) return

    function toggle() {
      const isTransfer = $("input[name='transaction[transaction_type]']:checked").val() === "transfer"
      destField.toggleClass("hidden", !isTransfer)
      if (isTransfer) {
        destField.insertAfter(".grid-cols-1.md\\:grid-cols-2.gap-8:first")
      }
    }

    $("input[name='transaction[transaction_type]']").on("change", toggle)
    toggle()
  },

  // ──────────────────────────────────────────────
  // 12. SEARCH MODAL (Navbar)
  // ──────────────────────────────────────────────
  openSearchModal() {
    const id = "search-modal"
    $("#" + id).remove()

    const modal = $(`
      <div id="${id}"
           class="fixed inset-0 z-[60] flex items-start justify-center pt-[15vh] bg-black/60 backdrop-blur-sm transition-opacity"
           onclick="if(event.target===this) Kitsune.closeSearchModal()">
        <div class="bg-zinc-900 border border-zinc-800 rounded-3xl shadow-2xl w-full max-w-lg mx-4 animate-fade-in-up overflow-hidden">
          <div class="p-4">
            <div class="flex items-center gap-3 bg-zinc-800 rounded-xl px-4 py-3 border border-zinc-700 focus-within:border-indigo-500 transition-colors">
              <svg class="w-5 h-5 text-zinc-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
              <input id="search-input" type="text" class="flex-1 bg-transparent text-zinc-100 text-base outline-none placeholder:text-zinc-500" placeholder="Buscar transações, ativos..." autofocus>
              <kbd class="hidden sm:inline-flex text-[10px] font-bold text-zinc-600 bg-zinc-900 px-2 py-0.5 rounded border border-zinc-700">esc</kbd>
            </div>
          </div>
          <div class="px-4 pb-4 space-y-1">
            <p class="text-[10px] font-bold uppercase tracking-widest text-zinc-600 px-1 mb-2">Atalhos</p>
            <a href="/dashboard/transactions" class="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-zinc-800/60 transition-colors text-zinc-400 hover:text-zinc-100">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75"><path stroke-linecap="round" stroke-linejoin="round" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/></svg>
              <span class="text-sm">Ver todas as transações</span>
            </a>
            <a href="/dashboard/investments" class="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-zinc-800/60 transition-colors text-zinc-400 hover:text-zinc-100">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75"><path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
              <span class="text-sm">Ir para investimentos</span>
            </a>
            <a href="/dashboard/accounts" class="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-zinc-800/60 transition-colors text-zinc-400 hover:text-zinc-100">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75"><path stroke-linecap="round" stroke-linejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/></svg>
              <span class="text-sm">Ver contas</span>
            </a>
          </div>
        </div>
      </div>
    `)

    $("body").append(modal)
    setTimeout(() => $("#search-input").focus(), 100)

    $("#search-input").on("keydown", function (e) {
      if (e.key === "Enter") {
        const q = $(this).val().trim()
        if (q) window.location.href = "/dashboard/transactions?search=" + encodeURIComponent(q)
      }
    })
  },

  closeSearchModal() {
    $("#search-modal").remove()
  },

  // ──────────────────────────────────────────────
  // 13. INVESTMENTS — Update Row After Save
  // ──────────────────────────────────────────────
  updateInvestmentRow(data) {
    const row = $(`tr[data-investment-id="${data.id}"]`)
    if (!row.length) return

    const cells = row.find("td")

    const qtyFmt = parseFloat(data.quantity).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 4 })
    const priceFmt = "R$ " + (data.current_price / 100).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 4 })
    const totalFmt = "R$ " + (data.current_value / 100).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    const avgFmt = "R$ " + (data.avg_price / 100).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 4 })

    cells.eq(2).find(".inline-edit").text(qtyFmt).data("value", data.quantity)
    cells.eq(3).html(`<span class="text-sm text-zinc-100">${avgFmt}</span>`)
    cells.eq(4).find(".inline-edit").text(priceFmt).data("value", (data.current_price / 100).toFixed(4))
    cells.eq(5).text(totalFmt)

    const glCell = cells.eq(6)
    const gl = data.gain_loss
    const glPct = data.gain_loss_pct
    if (data.avg_price > 0 && data.current_price > 0) {
      const sign = gl >= 0 ? "+" : ""
      const glFmt = sign + "R$ " + Math.abs(gl / 100).toLocaleString("pt-BR", { minimumFractionDigits: 2 })
      const arrow = gl >= 0 ? "▲" : "▼"
      glCell.html(`
        <div class="${gl >= 0 ? "text-emerald-400" : "text-red-400"}">
          <p class="text-sm font-bold tabular-nums">${glFmt}</p>
          <p class="text-[11px] font-medium opacity-70">${arrow} ${Math.abs(glPct).toFixed(2)}%</p>
        </div>
      `)
    } else {
      glCell.html('<span class="text-xs text-zinc-600">—</span>')
    }
  },

  // ──────────────────────────────────────────────
  // 14. FORM LOADING STATES
  // ──────────────────────────────────────────────
  formLoadingStates() {
    $(document).on("submit", "form", function () {
      const btn = $(this).find("[type=submit]")
      if (btn.length && !btn.data("no-loading")) {
        btn.data("original-text", btn.text())
        btn.prop("disabled", true)
        btn.css("opacity", "0.7")
        btn.text("Salvando...")
      }
    })

    $(document).on("ajax:complete ajax:error", "form", function () {
      const btn = $(this).find("[type=submit]")
      if (btn.length && btn.data("original-text")) {
        btn.prop("disabled", false)
        btn.css("opacity", "1")
        btn.text(btn.data("original-text"))
        btn.removeData("original-text")
      }
    })
  },

  // ──────────────────────────────────────────────
  // TOAST NOTIFICATIONS
  // ──────────────────────────────────────────────
  showToast(msg, type = "success") {
    const colors = {
      success: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
      error: "bg-red-500/10 text-red-400 border-red-500/20",
      info: "bg-indigo-500/10 text-indigo-400 border-indigo-500/20"
    }

    const toast = $(`
      <div class="animate-fade-in-up fixed top-4 right-4 z-[70] pointer-events-auto
                  ${colors[type] || colors.info} border px-5 py-3 rounded-xl shadow-lg backdrop-blur-md text-sm max-w-sm">
        ${msg}
      </div>
    `)
    $("body").append(toast)
    setTimeout(() => {
      toast.fadeOut(300, () => toast.remove())
    }, 3000)
  }
}

window.Kitsune = Kitsune
