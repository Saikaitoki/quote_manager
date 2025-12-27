// app/javascript/customer_staff_lookup.js

document.addEventListener("turbo:load", () => {
  const customerCodeInput = document.querySelector("#quote_customer_code");
  const customerNameInput = document.querySelector("#quote_customer_name");
  const customerBtn = document.querySelector("#lookupCustomerBtn");

  const staffCodeInput = document.querySelector("#quote_staff_code");
  const staffNameInput = document.querySelector("#quote_staff_name");
  const staffBtn = document.querySelector("#lookupStaffBtn");

  // ===== 共通ヘルパー =====

  function fetchJson(url) {
    return fetch(url).then((res) => {
      if (!res.ok) {
        if (res.status === 404) {
          throw new Error("NOT_FOUND");
        }
        throw new Error("SERVER_ERROR");
      }
      return res.json();
    });
  }

  function setValue(el, value) {
    if (!el) return;
    const old = el.value;
    el.value = value == null ? "" : String(value);
    if (old !== el.value) {
      el.dispatchEvent(new Event("input", { bubbles: true }));
      el.dispatchEvent(new Event("change", { bubbles: true }));
    }
  }

  // ===== 得意先ルックアップ =====

  // ===== 共通ヘルパー: エラー表示 =====
  function showError(input, errorId, message) {
    if (input) input.classList.add("is-invalid");
    const errEl = document.getElementById(errorId);
    if (errEl) {
      errEl.textContent = message;
      errEl.classList.add("d-block");
    }
  }

  function clearError(input, errorId) {
    if (input) input.classList.remove("is-invalid");
    const errEl = document.getElementById(errorId);
    if (errEl) {
      errEl.textContent = "";
      errEl.classList.remove("d-block");
    }
  }

  // ===== 得意先ルックアップ =====

  let lastCustomerCode = null;

  function lookupCustomer(options = {}) {
    const { force = false } = options;
    if (!customerCodeInput || !customerNameInput) return;

    const code = (customerCodeInput.value || "").trim();

    // 空 → 名前クリアだけして終了
    if (!code) {
      setValue(customerNameInput, "");
      clearError(customerCodeInput, "customer_lookup_error");
      lastCustomerCode = null;
      return;
    }

    // 同じコードで blur が連続した場合は無駄に叩かない
    if (!force && code === lastCustomerCode) return;

    if (customerBtn) customerBtn.disabled = true;
    clearError(customerCodeInput, "customer_lookup_error");

    fetchJson(`/kintone/customers/lookup?code=${encodeURIComponent(code)}`)
      .then((data) => {
        if (data.status !== "ok") {
          throw new Error("INVALID_RESPONSE");
        }
        const c = data.customer || {};
        // ここで得意先名を自動セット
        setValue(customerNameInput, c.name);

        if (c.rates) {
          setValue(document.getElementById("rate_proper"), c.rates.proper);
          setValue(document.getElementById("rate_kurashino"), c.rates.kurashino);
          setValue(document.getElementById("rate_common"), c.rates.common);
          setValue(document.getElementById("rate_essence"), c.rates.essence);
          setValue(document.getElementById("rate_porcelains"), c.rates.porcelains);
          setValue(document.getElementById("rate_f_symbol"), c.rates.f_symbol);
          setValue(document.getElementById("rate_h_symbol"), c.rates.h_symbol);
        }
        lastCustomerCode = code;
      })
      .catch((err) => {
        console.error("Customer lookup error", err);
        let msg = "得意先情報の取得に失敗しました。";
        if (err.message === "NOT_FOUND") {
          msg = "得意先マスタに該当するコードがありません。";
        }
        showError(customerCodeInput, "customer_lookup_error", msg);

        // 見つからなかった場合は名前をクリアしておく
        setValue(customerNameInput, "");
        lastCustomerCode = null;
      })
      .finally(() => {
        if (customerBtn) customerBtn.disabled = false;
      });
  }

  if (customerBtn && customerCodeInput) {
    // ボタンクリック → 強制ルックアップ
    customerBtn.addEventListener("click", (e) => {
      e.preventDefault();
      lookupCustomer({ force: true });
    });

    // コード入力欄フォーカスアウト → コードが変わっていればルックアップ
    customerCodeInput.addEventListener("blur", () => {
      lookupCustomer({ force: false });
    });

    // ★ コード欄：Enterで送信させず、ルックアップだけ実行
    customerCodeInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        lookupCustomer({ force: true });
      } else {
        // 文字入力中はエラーを消す（UX向上）
        clearError(customerCodeInput, "customer_lookup_error");
      }
    });
  }

  // ★ 得意先名欄：Enterを完全に無視（送信させない）
  if (customerNameInput) {
    customerNameInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
      }
    });
  }

  // ===== 担当者ルックアップ =====

  let lastStaffCode = null;

  function lookupStaff(options = {}) {
    const { force = false } = options;
    if (!staffCodeInput || !staffNameInput) return;

    const code = (staffCodeInput.value || "").trim();

    if (!code) {
      setValue(staffNameInput, "");
      clearError(staffCodeInput, "staff_lookup_error");
      lastStaffCode = null;
      return;
    }

    if (!force && code === lastStaffCode) return;

    if (staffBtn) staffBtn.disabled = true;
    clearError(staffCodeInput, "staff_lookup_error");

    fetchJson(`/kintone/staffs/lookup?code=${encodeURIComponent(code)}`)
      .then((data) => {
        if (data.status !== "ok") {
          throw new Error("INVALID_RESPONSE");
        }
        const s = data.staff || {};
        setValue(staffNameInput, s.name);
        lastStaffCode = code;
      })
      .catch((err) => {
        console.error("Staff lookup error", err);
        let msg = "担当者情報の取得に失敗しました。";
        if (err.message === "NOT_FOUND") {
          msg = "担当者マスタに該当するコードがありません。";
        }
        showError(staffCodeInput, "staff_lookup_error", msg);

        setValue(staffNameInput, "");
        lastStaffCode = null;
      })
      .finally(() => {
        if (staffBtn) staffBtn.disabled = false;
      });
  }

  if (staffBtn && staffCodeInput) {
    // ボタンクリック → 強制ルックアップ
    staffBtn.addEventListener("click", (e) => {
      e.preventDefault();
      lookupStaff({ force: true });
    });

    // コード欄フォーカスアウト → ルックアップ
    staffCodeInput.addEventListener("blur", () => {
      lookupStaff({ force: false });
    });

    // ★ コード欄：Enterで送信させず、ルックアップだけ実行
    staffCodeInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        lookupStaff({ force: true });
      } else {
        clearError(staffCodeInput, "staff_lookup_error");
      }
    });
  }
  // ★ 担当者名欄：Enterを完全に無視（送信させない）
  if (staffNameInput) {
    staffNameInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
      }
    });
  }

  // ===== 編集画面などで初期値が入っている場合の自動取得 =====
  if (customerCodeInput && customerCodeInput.value.trim()) {
    // ページロード時はキャッシュを使わず最新を取りに行くか、あるいはキャッシュさせるか。
    // ここでは念のため force: true で取得して掛率などをセットする
    lookupCustomer({ force: true });
  }
});
