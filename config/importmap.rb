# Pin npm packages by running ./bin/importmap

pin "application"
pin "items", to: "items.js"
pin "customer_staff_lookup"

# ✅ Turbo (正しいCDNパス)
pin "@hotwired/turbo-rails", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.4/dist/turbo.es2017-esm.js"

# ✅ Stimulus
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# ✅ Bootstrap & Popper
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
