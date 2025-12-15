// app/javascript/items.js

// ===============================
//  カタログNoに基づく掛率の判定
// ===============================
function resolveRate(catalogNo) {
  if (!catalogNo) return "";

  const cat = catalogNo.trim();

  // 1. 完全一致/リスト判定
  const properList = ["As", "At", "Ar", "Cp"];
  const kurashinoList = ["Al", "Ag", "Ch"];

  if (properList.includes(cat)) {
    return getRateValue("rate_proper");
  }
  if (kurashinoList.includes(cat)) {
    return getRateValue("rate_kurashino");
  }
  if (cat === "Bc") {
    return getRateValue("rate_common");
  }
  if (cat === "Be") {
    return getRateValue("rate_essence");
  }
  if (cat === "Bp") {
    return getRateValue("rate_porcelains");
  }

  // 2. 接頭辞判定
  if (cat.startsWith("F")) {
    return getRateValue("rate_f_symbol");
  }
  if (cat.startsWith("H") || cat.startsWith("J")) {
    return getRateValue("rate_h_symbol");
  }
  return "";
}

function getRateValue(elementId) {
  const el = document.getElementById(elementId);
  return el ? el.value : "";
}

// ---------------------------
// ページ初期化（Turbo & 通常）
// ---------------------------
function initPage() {
  initializeQuoteItems();
  enableEnterFocusJump();
}

document.addEventListener("turbo:load", initPage);
document.addEventListener("DOMContentLoaded", initPage);

function initializeQuoteItems() {
  const itemModal = document.getElementById("itemModal");
  if (!itemModal) return;

  // 同じページで二重初期化しない
  if (itemModal.dataset.initialized === "true") return;
  itemModal.dataset.initialized = "true";

  const modalInstance = bootstrap.Modal.getOrCreateInstance(itemModal);
  let editingCard = null;

  // モーダル内のフィールド対応表（キー名は items テーブルのカラムに対応）
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
  };

  // ---------------------------
  // カード1枚分にクリックイベントを付与
  // ---------------------------
  function setupCardHandlers(card) {
    if (!card || card.dataset.bound === "true") return;
    card.dataset.bound = "true";

    card.addEventListener("click", (e) => {
      // 削除ボタンクリック
      if (e.target.closest(".remove-item")) {
        e.preventDefault();
        card.remove();
        return;
      }

      // 編集：カードどこかをクリック
      const raw = card.dataset.item || "{}";
      let data = {};
      try {
        data = JSON.parse(raw);
      } catch (err) {
        console.warn("data-item の JSON が不正です", err);
      }

      editingCard = card;
      fillModalFromData(itemModal, FIELD_ID_MAP, data);
      modalInstance.show();
    });
  }

  // ---------------------------
  // 既存カードに data-item を補完＋ハンドラ付与
  // ---------------------------
  const existingCards = document.querySelectorAll(".quote-item-card");
  existingCards.forEach((card) => {
    // data-item がなければ hidden から補完
    if (!card.dataset.item) {
      const data = {};
      Object.keys(FIELD_ID_MAP).forEach((key) => {
        const hidden = card.querySelector(`[name*="[${key}]"]`);
        data[key] = hidden ? hidden.value : "";
      });
      card.dataset.item = JSON.stringify(data);
    }

    // クリックハンドラを付与
    setupCardHandlers(card);
  });

  // ======================
  //  行追加ボタン（＋行を追加）
  // ======================
  const openBtn = document.getElementById("openModalBtn");
  if (openBtn && !openBtn.dataset.bound) {
    openBtn.dataset.bound = "true";
    openBtn.addEventListener("click", (e) => {
      e.preventDefault();
      editingCard = null;
      resetModalInputs(itemModal);
      modalInstance.show();
    });
  }

  // ======================
  //  「明細を保存」ボタン
  // ======================
  const saveButton = document.getElementById("saveItem");
  if (saveButton && !saveButton.dataset.bound) {
    saveButton.dataset.bound = "true";

    saveButton.addEventListener("click", () => {
      requestAnimationFrame(() => {
        const itemsTable = document.getElementById("items-table");
        if (!itemsTable) return;

        const itemData = collectModalValues(itemModal, FIELD_ID_MAP);

        if (editingCard) {
          // 編集モード
          updateCardDisplay(editingCard, itemData);
          editingCard.dataset.item = JSON.stringify(itemData);
          editingCard = null;
        } else {
          // ==========================
          // 新規追加（template から fragment を生成）
          // ==========================
          const templateEl = document.querySelector("template#item-template");
          if (!templateEl) {
            console.error("item-template が見つかりません");
            return;
          }

          const newId = Date.now();
          const html = templateEl.innerHTML.replace(/new_items/g, newId);

          const temp = document.createElement("tbody");
          temp.innerHTML = html.trim();

          const newCard = temp.querySelector(".quote-item-card");
          if (!newCard) {
            console.error("template 内に .quote-item-card が見つかりません");
            return;
          }

          const tbody = itemsTable.querySelector("tbody") || itemsTable;
          tbody.prepend(newCard);

          updateCardDisplay(newCard, itemData);
          newCard.dataset.item = JSON.stringify(itemData);
          setupCardHandlers(newCard); // ★新規カードにもハンドラ
        }

        modalInstance.hide();
        resetModalInputs(itemModal);
      });
    });
  }

  // ======================
  //  商品CD ルックアップ
  // ======================
  const productCdInput = itemModal.querySelector("#item_product_cd");
  const lookupBtn = itemModal.querySelector("#lookupProductBtn");

  let lastLookupCode = null;

  if (lookupBtn && productCdInput && !lookupBtn.dataset.bound) {
    lookupBtn.dataset.bound = "true";

    // ボタンクリック → 強制ルックアップ
    lookupBtn.addEventListener("click", (e) => {
      e.preventDefault();
      lookupProduct({ force: true });
    });

    // フォーカスアウト → コードが変わっていればルックアップ
    productCdInput.addEventListener("blur", () => {
      lookupProduct({ force: false });
    });
  }

  function lookupProduct(options = {}) {
    const { force = false } = options;
    if (!productCdInput) return;

    const code = (productCdInput.value || "").trim();

    // 空欄 → 関連フィールドをクリア
    if (!code) {
      clearProductFields();
      lastLookupCode = null;
      return;
    }

    // 同じコード & 強制でない → 何もしない
    if (!force && code === lastLookupCode) return;

    if (lookupBtn) lookupBtn.disabled = true;

    fetch(`/kintone/products/lookup?code=${encodeURIComponent(code)}`)
      .then((response) => {
        if (!response.ok) {
          if (response.status === 404) throw new Error("NOT_FOUND");
          throw new Error("SERVER_ERROR");
        }
        return response.json();
      })
      .then((data) => {
        if (data.status !== "ok") {
          throw new Error("INVALID_RESPONSE");
        }

        const p = data.product || {};

        // 商品情報のセット
        setField("#item_product_name", p.name);
        setField("#item_price", p.price);
        setField("#item_special_price", p.special_price);
        setField("#item_stock", p.stock);
        setField("#item_inner_qty", p.inner_qty);
        setField("#item_catalog_no", p.catalog_no);
        setField("#item_page", p.page);
        setField("#item_row", p.row);
        setField("#item_package", p.package);

        lastLookupCode = code;

        // ルックアップ後に掛率や数量が入っていれば再計算

        // ★ カタログNoに基づく掛率の自動適用
        const catalogNo = p.catalog_no || "";
        const resolvedRate = resolveRate(catalogNo);
        if (resolvedRate) {
          setField("#item_rate", resolvedRate);
        }

        handlePriceRelatedChange();
      })
      .catch((err) => {
        console.error("Product lookup error", err);
        if (err.message === "NOT_FOUND") {
          alert("商品マスタに該当する商品CDがありません。");
        } else {
          alert("商品情報の取得に失敗しました。");
        }
        clearProductFields();
        lastLookupCode = null;
      })
      .finally(() => {
        if (lookupBtn) lookupBtn.disabled = false;
      });
  }

  function clearProductFields() {
    setField("#item_product_name", "");
    setField("#item_price", "");
    setField("#item_special_price", "");
    setField("#item_stock", "");
    setField("#item_inner_qty", "");
    setField("#item_catalog_no", "");
    setField("#item_page", "");
    setField("#item_row", "");
    setField("#item_package", "");
    setField("#item_lower_price", "");
    setField("#item_amount", "");
  }

  function setField(selector, value) {
    const el = itemModal.querySelector(selector);
    if (!el) return;
    el.value = value == null ? "" : String(value);
  }

  // ======================
  //  下代・金額の自動計算
  // ======================
  const priceInput = itemModal.querySelector("#item_price");          // 上代
  const specialInput = itemModal.querySelector("#item_special_price");  // 特別上代
  const rateInput = itemModal.querySelector("#item_rate");           // 掛率
  const qtyInput = itemModal.querySelector("#item_quantity");       // 数量
  const lowerPriceInput = itemModal.querySelector("#item_lower_price");    // 下代
  const amountInput = itemModal.querySelector("#item_amount");         // 金額

  function num(el) {
    if (!el) return 0;
    const v = (el.value || "").replace(/,/g, "").trim();
    const n = Number(v);
    return Number.isFinite(n) ? n : 0;
  }

  // 上代・特別上代・掛率が変わったら下代＋金額を再計算
  function handlePriceRelatedChange() {
    if (!lowerPriceInput) return;

    const upper = num(priceInput);
    const special = num(specialInput);
    const rate = num(rateInput);   // 45, 50 など
    const basePrice = special > 0 ? special : upper;

    if (basePrice > 0 && rate > 0) {
      const lower = Math.floor(basePrice * (rate * 0.01)); // 掛率は百分率
      lowerPriceInput.value = lower || "";
    } else {
      lowerPriceInput.value = "";
    }

    recalcAmount();
  }

  // 数量 or 下代 が変わったら金額だけ更新
  function recalcAmount() {
    if (!amountInput) return;
    const qty = num(qtyInput);
    const lower = num(lowerPriceInput);
    const amount = lower * qty;
    amountInput.value = amount || "";
  }

  if (priceInput) {
    priceInput.addEventListener("input", handlePriceRelatedChange);
    priceInput.addEventListener("blur", handlePriceRelatedChange);
  }
  if (specialInput) {
    specialInput.addEventListener("input", handlePriceRelatedChange);
    specialInput.addEventListener("blur", handlePriceRelatedChange);
  }
  if (rateInput) {
    rateInput.addEventListener("input", handlePriceRelatedChange);
    rateInput.addEventListener("blur", handlePriceRelatedChange);
  }
  if (qtyInput) {
    qtyInput.addEventListener("input", recalcAmount);
    qtyInput.addEventListener("blur", recalcAmount);
  }
  if (lowerPriceInput) {
    lowerPriceInput.addEventListener("input", recalcAmount);
    lowerPriceInput.addEventListener("blur", recalcAmount);
  }

  // ======================
  //  共通ヘルパー
  // ======================
  function collectModalValues(root, fieldMap) {
    const data = {};
    Object.keys(fieldMap).forEach((key) => {
      const selector = fieldMap[key];
      const el = root.querySelector(selector);
      data[key] = el ? el.value.trim() : "";
    });
    return data;
  }

  function fillModalFromData(root, fieldMap, data) {
    Object.keys(fieldMap).forEach((key) => {
      const selector = fieldMap[key];
      const el = root.querySelector(selector);
      if (!el) return;
      const v = data[key];
      el.value = v == null ? "" : String(v);
    });
  }

  function updateCardDisplay(card, data) {
    if (!card) {
      console.warn("updateCardDisplay: card element is null. DOM構造を確認してください。");
      return;
    }

    // 表示用テキスト（template 側にクラスがあるカードのみ効く）
    card.querySelector(".product_cd_cell")
      ?.replaceChildren(document.createTextNode(data.product_cd || ""));
    card.querySelector(".product_name_cell")
      ?.replaceChildren(document.createTextNode(data.product_name || ""));
    card.querySelector(".difference_actual_cell")
      ?.replaceChildren(document.createTextNode(data.difference_actual || ""));
    card.querySelector(".quantity_cell")
      ?.replaceChildren(document.createTextNode(data.quantity || ""));
    card.querySelector(".rate_cell")
      ?.replaceChildren(document.createTextNode(data.rate || ""));

    // hidden field 更新
    for (const key in data) {
      const input = card.querySelector(`[name*="[${key}]"]`);
      if (input) input.value = data[key];
    }
  }

  function resetModalInputs(root) {
    root.querySelectorAll("input").forEach((i) => (i.value = ""));
  }
}

// ===============================
//  Enter でフォーカスを次の欄へ送る
//  商品コード → 数量 → 掛率 → そこで止まる
// ===============================
function enableEnterFocusJump() {
  const productCd = document.querySelector("#item_product_cd");
  const quantity = document.querySelector("#item_quantity");
  const rate = document.querySelector("#item_rate");

  // 商品コード
  if (productCd && !productCd.dataset.bound) {
    productCd.dataset.bound = "true";
    productCd.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        const lookupBtn = document.querySelector("#lookupProductBtn");
        if (lookupBtn) lookupBtn.click();
        setTimeout(() => quantity?.focus(), 50);
      }
    });
  }

  // 数量
  if (quantity && !quantity.dataset.bound) {
    quantity.dataset.bound = "true";
    quantity.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        rate?.focus();
      }
    });
  }


  // 掛率
  if (rate && !rate.dataset.bound) {
    rate.dataset.bound = "true";
    rate.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        rate.blur(); // キーボードを閉じるためにフォーカスを外す
      }
    });
  }
}
