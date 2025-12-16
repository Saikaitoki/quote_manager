// app/javascript/application.js

// ✅ Turbo (importmap経由)
import "@hotwired/turbo-rails"

// ✅ Bootstrap (importmap経由)
import * as bootstrap from "bootstrap"

// ✅ Stimulus Controllers
import "./controllers"

// ✅ 自作スクリプト
import "./items"
import "./customer_staff_lookup"

// ✅ Bootstrap をグローバル化（モーダル用）
window.bootstrap = bootstrap
