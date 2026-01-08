# 見積管理システム 仕様書

## 1. システム概要
本システムは、見積書の作成、管理、およびKintoneとのデータ連携を行うWebアプリケーションです。

### 1-1. 基本情報
*   **システム名**: 見積管理システム
*   **本番URL**: [https://quote-manager-yqg8.onrender.com](https://quote-manager-yqg8.onrender.com)
*   **対応デバイス**: Androidタブレット・スマートフォン (推奨), PC

### 1-2. 機能一覧
*   **認証**: Kintone連携またはBasic認証 (環境依存)
*   **見積管理**: 一覧表示、詳細表示、新規作成、編集、削除（論理削除/物理削除）
*   **商品連携**: Kintone商品マスタからの検索、JANコード/品番スキャン対応
*   **在庫連携**: 商品検索時のリアルタイム在庫・仮押在庫確認、見積登録時の仮押在庫更新
*   **Kintone同期**: 見積データのKintoneアプリへの登録・更新

## 2. 画面一覧

| 画面名 | URLパス | 機能概要 |
| :--- | :--- | :--- |
| **ホーム (見積一覧)** | `/` | 作成済みの見積一覧を表示。検索、フィルタリング、新規作成ボタン、Kintone同期ボタン配置。 |
| **見積詳細** | `/quotes/:id` | 見積内容の詳細表示。編集・削除・印刷（Kintoneへ遷移）ボタン配置。 |
| **見積作成** | `/quotes/new` | 新規見積入力フォーム。得意先・担当者選択、商品明細行の追加。 |
| **見積編集** | `/quotes/:id/edit` | 既存見積の編集フォーム。 |
| **商品検索モーダル** | - | 見積作成・編集画面内でモーダル表示。商品CDスキャン・検索および数量入力。 |

## 3. データベース設計 (PostgreSQL)

### 3-1. quotes テーブル (見積ヘッダ)

| カラム名 | 型 | 説明 |
| :--- | :--- | :--- |
| `id` | bigint | 主キー |
| `customer_code` | string | 得意先コード (Kintone連携) |
| `customer_name` | string | 得意先名 |
| `ship_to_name` | string | 直送先名 |
| `staff_code` | string | 担当者コード (Kintone連携) |
| `staff_name` | string | 担当者名 |
| `date` | date | (未使用 / 旧仕様?) |
| `created_on` | date | 見積作成日 |
| `note` | text | 備考 |
| `status` | string | ステータス (`pending`, `confirmed` 等) |
| `subtotal` | integer | 小計 |
| `total` | integer | 合計 (未使用?) |
| `stock_status` | string | 在庫確保ステータス (`secured`: 確保中, `released`: 解放済) |
| `kintone_record_id` | string | 連携先のKintoneレコードID |
| `kintone_revision` | integer | Kintoneレコードのリビジョン番号 |
| `raw_payload` | text | (デバッグ用) Kintone送信データの控え |
| `created_at` | datetime | 作成日時 |
| `updated_at` | datetime | 更新日時 |

### 3-2. items テーブル (見積明細)

| カラム名 | 型 | 説明 |
| :--- | :--- | :--- |
| `id` | bigint | 主キー |
| `quote_id` | bigint | 外部キー (quotes.id) |
| `product_cd` | string | 商品コード |
| `product_name` | string | 商品名 |
| `quantity` | integer | 数量 |
| `unit_price` | integer | (未使用? 下代を使用) |
| `upper_price` | integer | 上代 |
| `lower_price` | integer | 下代 (単価) |
| `special_upper_price` | integer | 特別上代 |
| `rate` | decimal(5,2) | 掛率 |
| `amount` | integer | 金額 (数量 × 下代) |
| `difference_actual` | integer | 差引実 (在庫数) |
| `inner_box_count` | integer | 内箱入数 |
| `catalog_no` | string | カタログNo (記号) |
| `page` | string | 頁 |
| `row` | string | 行 |
| `package` | string | 荷姿 |

## 4. 外部インターフェース仕様 (Kintone)

### 4-1. 見積アプリ (連携先)
本システムからデータを登録・更新します。

| Kintoneフィールド名 | フィールドコード | Kintoneタイプ | 備考 |
| :--- | :--- | :--- | :--- |
| 見積番号 | `見積番号` | レコード番号 | システム採番 |
| 得意先コード | `得意先コード` | 数値 | |
| 得意先名 | `得意先名` | 文字列 (1行) | |
| 直送先名 | `直送先名` | 文字列 (1行) | |
| 担当者コード | `担当者コード` | 数値 | |
| 担当者 | `担当者` | 文字列 (1行) | |
| 作成日 | `作成日` | 日付 | |
| 備考 | `備考` | 文字列 (複数行) | |
| 小計 | `小計` | 数値 | |
| **明細テーブル** | `明細` | サブテーブル | |
| (明細) 商品CD | `商品CD` | 文字列 (1行) | |
| (明細) 商品名 | `商品名` | 文字列 (1行) | |
| (明細) 数量 | `数量` | 数値 | |
| (明細) 掛率 | `掛率` | 数値 | |
| (明細) 上代 | `上代` | 数値 | |
| (明細) 下代 | `下代` | 数値 | |
| (明細) 金額 | `金額` | 数値 | |
| (明細) カタログNo | `カタログNo` | 文字列 (1行) | |

### 4-2. 商品マスタ (参照用)
商品検索時にAPIで最新情報を取得します。

*   **アプリID**: 環境変数 `KINTONE_PRODUCT_APP_ID`
*   **検索キー**: `商品CD` または `JANコード` (実装依存)

| 取得項目 | フィールドコード | 説明 |
| :--- | :--- | :--- |
| 商品CD | `商品CD` | |
| 商品名 | `商品名` | |
| 在庫数 | `在庫数` | 実在庫 |
| 仮押数量 | `仮押数量` | 他の見積で確保中の数量 |
| 上代 | `上代` | |
| 特別上代 | `特別上代` | |
| 内箱入数 | `内箱入数` | |
| 記号 | `記号` | カタログNo |
| 頁CD | `頁CD` | |
| 行CD | `行CD` | |
| 荷姿 | `荷姿` | |

### 4-3. 得意先マスタ (参照用)
作成時に得意先コードから情報を引き当てます。

*   **アプリID**: 環境変数 `KINTONE_CUSTOMER_APP_ID`
*   **検索キー**: `得意先コード`

| 取得項目 | フィールドコード | 説明 |
| :--- | :--- | :--- |
| 得意先コード | `得意先コード` | |
| 得意先名 | `得意先名` | |
| 各種掛率 | `プロパー掛率` `クラシノウツワ掛率` `common掛率` `essence掛率` `The_Porcelains掛率` `F記号掛率` `H記号掛率` | 商品カタログごとの掛率 |

### 4-4. 営業担当者マスタ (参照用)
担当者コードから氏名を引き当てます。

*   **アプリID**: 環境変数 `KINTONE_STAFF_APP_ID`
*   **検索キー**: `営業担当者コード`

| 取得項目 | フィールドコード | 説明 |
| :--- | :--- | :--- |
| コード | `営業担当者コード` | |
| 氏名 | `営業担当者` | |

## 5. インフラ構成
*   **Platform**: Render (Web Service)
*   **Database**: PostgreSQL 14+ (Render Managed)
*   **Assets**: Propshaft + esbuild + dart-sass
*   **Ruby**: 3.4.7
*   **Rails**: 8.1.0

## 6. 環境変数定義

| 変数名 | 必須 | 説明 |
| :--- | :--- | :--- |
| `RAILS_MASTER_KEY` | Yes | 暗号化されたクレデンシャルの復号キー |
| `DATABASE_URL` | Yes | DB接続情報 (Renderでは自動設定) |
| `KINTONE_DOMAIN` | Yes | Kintoneドメイン (`xxx.cybozu.com`) |
| `KINTONE_QUOTES_APP` | Yes | 見積アプリID |
| `KINTONE_API_TOKEN` | Yes | 見積アプリAPIトークン |
| `KINTONE_PRODUCT_APP_ID` | Yes | 商品マスタアプリID |
| `KINTONE_PRODUCT_API_TOKEN` | No | 商品マスタAPIトークン(省略時は共通トークン) |
| `KINTONE_CUSTOMER_APP_ID` | Yes | 得意先マスタアプリID |
| `KINTONE_CUSTOMER_API_TOKEN` | No | 得意先マスタAPIトークン |
| `KINTONE_STAFF_APP_ID` | Yes | 担当者マスタアプリID |
| `KINTONE_STAFF_API_TOKEN` | No | 担当者マスタAPIトークン |
