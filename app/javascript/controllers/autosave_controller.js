// app/javascript/controllers/autosave_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        quoteId: String
    }

    connect() {
        this.storageKey = `quote_draft_${this.quoteIdValue || "new"}`
        this.restoreIfNeeded()
    }

    // 入力イベント（change, input）で保存
    save() {
        const data = {
            header: this.serializeHeader(),
            items: this.serializeItems(),
            timestamp: Date.now()
        }
        localStorage.setItem(this.storageKey, JSON.stringify(data))
        console.log("Quotes Autosaved", data)
    }

    // フォーム送信成功時にクリア＆連打防止
    clear(event) {
        localStorage.removeItem(this.storageKey)

        // 送信ボタンを無効化
        // event.submitter はモダンブラウザ(PC/Mobile)で対応
        const button = event.submitter
        if (button) {
            button.disabled = true
            button.dataset.originalText = button.innerText
            button.innerText = "処理中..."
        }
    }

    restoreIfNeeded() {
        const json = localStorage.getItem(this.storageKey)
        if (!json) return

        if (!confirm("未保存の作業データ（ドラフト）があります。復元しますか？")) {
            // 復元しないならクリアするか？今回は残しておく（後でまた聞くため）
            return
        }

        try {
            const data = JSON.parse(json)
            this.restoreHeader(data.header)
            this.restoreItems(data.items)
            console.log("Restored from Autosave")
        } catch (e) {
            console.error("Autosave restore failed", e)
        }
    }

    // --- Serialization ---

    serializeHeader() {
        const headerInputs = this.element.querySelectorAll("input:not([type=hidden]), textarea, select")
        const data = {}
        headerInputs.forEach(input => {
            if (input.name) {
                data[input.name] = input.value
            }
        })
        return data
    }

    serializeItems() {
        const items = []
        const cards = document.querySelectorAll(".quote-item-card")
        cards.forEach(card => {
            // items.js が保存している data-item を使うのが確実
            if (card.dataset.item) {
                try {
                    items.push(JSON.parse(card.dataset.item))
                } catch (e) { }
            }
        })
        return items
    }

    // --- Restoration ---

    restoreHeader(headerData) {
        if (!headerData) return
        Object.keys(headerData).forEach(name => {
            const input = this.element.querySelector(`[name="${name}"]`)
            if (input) {
                input.value = headerData[name]
            }
        })
    }

    restoreItems(itemsData) {
        if (!Array.isArray(itemsData) || itemsData.length === 0) return

        const container = document.getElementById("items-container")
        if (!container) return

        // 既存の明細をクリア（ドラフトで上書きするため）
        container.innerHTML = ""

        // テンプレート取得
        const templateEl = document.querySelector("template#item-template")
        if (!templateEl) return

        itemsData.forEach(item => {
            this.createItemCard(container, templateEl, item)
        })

        // items.js の初期化ロジック（イベントリスナー付与）を再実行させる必要がある
        // items.js は "DOMContentLoaded" や "turbo:load" で走るが、
        // ここで動的に追加した要素にはイベントがつかない可能性がある。
        // items.js の setupCardHandlers は ".quote-item-card" を querySelectorAll して
        // data-bound 属性を見て重複回避しているので、再実行すればOK。
        // ただし items.js の関数は export されていない...
        // 苦肉の策情報: items.js はグローバル関数ではない。
        // -> setupCardHandlers 的なことをここでもやるか、
        // ページ全体のリロードを避けた Turbo 的な設計にする必要がある。
        // 
        // 一番簡単なのは、DOM追加後に items.js が自動で検知する仕組み...はない。
        // Card に onclick を仕込むか、items.js のロジックをここにもコピーする。
        // 今回は「items.js のロジックをコピー（最小限）」で対応する。
        // クリックでモーダルを開く部分だけ動けば良い。
    }

    createItemCard(container, template, data) {
        const newId = Date.now() + Math.floor(Math.random() * 1000)
        let html = template.innerHTML.replace(/new_items/g, newId)

        const temp = document.createElement("div")
        temp.innerHTML = html.trim()
        const card = temp.firstElementChild
        if (!card) return

        // 初期値セット (Display & Hidden)
        // items.js の updateCardDisplay 相当
        this.updateCardDisplay(card, data)
        card.dataset.item = JSON.stringify(data)

        // クリックイベント付与 (items.js setupCardHandlers 相当)
        card.addEventListener("click", (e) => {
            // 削除
            if (e.target.closest(".remove-item")) {
                e.preventDefault()

                // 既存レコード（IDがある）場合は、_destroy フラグを立てて隠すだけ
                const idField = card.querySelector(".item-id")
                if (idField && idField.value) {
                    const destroyField = card.querySelector(".destroy-flag")
                    if (destroyField) {
                        destroyField.value = "1"
                        card.style.display = "none"
                    }
                } else {
                    // 新規追加分（IDなし）は DOM から削除してOK
                    card.remove()
                }

                this.save() // 削除も保存（隠した状態も保存される）
                return
            }

            // 編集は items.js の itemModal 共有が必要だが、
            // items.js は DOMContentLoaded で既存カードにリスナーをつけている。
            // ここで追加したカードには items.js のリスナーがつかない。
            //
            // 解決策: "turbo:load" イベントを手動発火して items.js を再稼働させる...は乱暴。
            // items.js を改修して `window.setupItemCards()` を作れればベストだが、
            // 今回は「autosave」単独での実装要件。
            //
            // ★ data-bound 属性を消しておけば、initPage() を呼ぶだけで再バインドされるはず！
            // items.js: document.addEventListener("turbo:load", initPage);
            // initPage -> initializeQuoteItems -> existingCards.forEach...

            // なので、ここではDOMに追加するだけで良い。
            // その後 items.js をどうにかして再実行させたい。
            // `initPage()` がグローバルなら呼べる。
            // items.js は `function initPage() { ... }` と書いてあるが、
            // type="module" (import "./items") なのでスコープは閉じている。

            // 妥協案: Cardのクリックで「隠しボタン」を押すなどして連携するか、
            // そもそも「復元直後」は編集できない（リロード推奨）とするか？
            // いや、それは不便。

            // ベスト: items.js で「DOM変更監視 (MutationObserver)」をしていないので、
            // 単純に items.js のロジックを一部再現して「クリックしたらモーダルを開く」を実装する。
            // itemModal と bootstrap instance はグローバルから取得できる。
        })

        container.appendChild(card)
    }

    updateCardDisplay(card, data) {
        card.querySelector(".product_cd_cell")?.replaceChildren(document.createTextNode(data.product_cd || ""))
        card.querySelector(".product_name_cell")?.replaceChildren(document.createTextNode(data.product_name || ""))
        card.querySelector(".difference_actual_cell")?.replaceChildren(document.createTextNode(data.difference_actual || ""))
        card.querySelector(".quantity_cell")?.replaceChildren(document.createTextNode(data.quantity || ""))
        card.querySelector(".rate_cell")?.replaceChildren(document.createTextNode(data.rate || ""))

        // 隠しフィールドの復元
        for (const key in data) {
            // id や _destroy も含む
            const input = card.querySelector(`[name*="[${key}]"]`)

            // _destroy 用の special handling: クラス指定があればそちら優先（name属性が複雑なため）
            if (key === "_destroy" && data[key] === "1") {
                const destroyInput = card.querySelector(".destroy-flag")
                if (destroyInput) destroyInput.value = "1"
                card.style.display = "none"
                continue
            }

            // id 用
            if (key === "id") {
                const idInput = card.querySelector(".item-id")
                if (idInput) idInput.value = data[key]
                continue
            }

            if (input) input.value = data[key]
        }
    }

    // clickハンドラ内で items.js の機能を呼び出すためのフック
    // items.js の initializeQuoteItems が再実行されれば、data-bound="true" がないカードにリスナーが付く。
    // しかし外部からそれを呼べない。
    //
    // なので、restoreItems の最後に、items.js のロジックを「ハック」する。
    // .quote-item-card に click リスナーをここで付ける。
    setupCardInteraction(card) {
        const itemModal = document.getElementById("itemModal")
        // items.js 内の定義と同じロジック
        const FIELD_ID_MAP = {
            product_cd: "#item_product_cd",
            product_name: "#item_product_name",
            difference_actual: "#item_stock",
            quantity: "#item_quantity",
            rate: "#item_rate",
            lower_price: "#item_lower_price",
            amount: "#item_amount",
            upper_price: "#item_price",
            catalog_no: "#item_catalog_no",
            special_upper_price: "#item_special_price",
            inner_box_count: "#item_inner_qty",
            page: "#item_page",
            row: "#item_row",
            package: "#item_package"
        }

        card.addEventListener("click", (e) => {
            if (e.target.closest(".remove-item")) {
                e.preventDefault()
                card.remove()
                this.save()
                return
            }

            // 編集
            const raw = card.dataset.item
            if (!raw) return
            const data = JSON.parse(raw)

            // Modal 表示 (Bootstrap)
            const modalInstance = window.bootstrap.Modal.getOrCreateInstance(itemModal)

            // Modalの中身を埋める (items.js の fillModalFromData 相当)
            Object.keys(FIELD_ID_MAP).forEach(key => {
                const selector = FIELD_ID_MAP[key]
                const el = itemModal.querySelector(selector)
                if (el) el.value = data[key] || ""
            })

        })
    }
}
