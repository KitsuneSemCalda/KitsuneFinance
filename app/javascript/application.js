// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "htmx.org"
import Alpine from "alpinejs"

window.Alpine = Alpine
Alpine.start()

document.addEventListener("htmx:configRequest", (event) => {
  const meta = document.querySelector('meta[name="csrf-token"]');
  if (meta) {
    event.detail.headers['X-CSRF-Token'] = meta.content;
  }
});
