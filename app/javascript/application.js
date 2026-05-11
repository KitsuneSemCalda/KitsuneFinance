// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "htmx.org"
import Alpine from "alpinejs"
import * as Chart from "chart.js"

window.Alpine = Alpine
window.Chart = Chart.default || Chart
Alpine.start()

document.addEventListener("turbo:load", () => {
  if (!window.Alpine.initialized) {
    window.Alpine.start()
    window.Alpine.initialized = true
  }
})
