// app/javascript/application.js

// ✅ Turbo (importmap経由)
import "@hotwired/turbo-rails"

// ✅ Bootstrap (importmap経由) ← CSSではなくJSだけ
import * as bootstrap from "bootstrap"

// ✅ 自作スクリプト
import "./items"
import "./customer_staff_lookup"

// ✅ スタイルシート (Esbuildで処理)
// import "./stylesheets/application.scss"

// ✅ Bootstrap をグローバル化（モーダル用）
window.bootstrap = bootstrap

