# 見積管理システム 引継ぎ資料

## 1. システム概要
本システムは、見積書の作成・管理を行うWebアプリケーションです。
社給Android端末での利用を想定しており、バーコードリーダーを用いた商品入力や、Kintoneとのデータ連携機能を有しています。

*   **本番環境URL**: https://quote-manager-yqg8.onrender.com
*   **主な機能**:
    *   見積書の新規作成・編集・削除
    *   商品コード/JANコードのスキャン入力
    *   Kintoneからの顧客・商品データ取得
    *   在庫管理（仮押在庫の計算）
    *   見積書のPDF印刷（Kintone経由）

## 2. 技術スタック

### バックエンド
*   **Framework**: Ruby on Rails 8.1.0
*   **Language**: Ruby 3.4.7
*   **Database**:
    *   Development: SQLite3
    *   Production: PostgreSQL (Render Managed DB)

### フロントエンド
*   **CSS Framework**: Bootstrap 5.3
*   **JS Libraries**: Hotwire (Turbo, Stimulus)
*   **Build Tools**: esbuild, dart-sass

### インフラ・デプロイ
*   **Platform**: Render.com (Web Service + Managed PostgreSQL)
*   **Deployment**: GitHub連携による自動デプロイ (`render.yaml` ブループリント)

## 3. 開発環境のセットアップ (Windows/Mac共通)

### 前提条件
以下のツールがインストールされていること。
*   Ruby 3.4.7
*   Node.js & Yarn
*   Git

### セットアップ手順
1.  **リポジトリのクローン**
    ```bash
    git clone <repository-url>
    cd quote_manager
    ```

2.  **依存ライブラリのインストール**
    ```bash
    bundle install
    yarn install
    ```

3.  **データベースのセットアップ**
    ```bash
    bin/rails db:setup
    ```

4.  **環境変数の設定**
    `.env` ファイルを作成し、以下の環境変数を設定してください。
    
    | 変数名 | 説明 | 例 |
    | :--- | :--- | :--- |
    | `KINTONE_DOMAIN` | Kintoneのドメイン | `example.cybozu.com` |
    | `KINTONE_QUOTES_APP` | 見積アプリのアプリID | `100` |
    | `KINTONE_API_TOKEN` | 見積アプリのAPIトークン | `abcdef12345...` |
    | `KINTONE_PRODUCT_APP_ID` | 商品マスタのアプリID | `101` |
    | `KINTONE_PRODUCT_API_TOKEN` | 商品マスタのAPIトークン | `...` |
    | `KINTONE_CUSTOMER_APP_ID` | 得意先マスタのアプリID | `102` |
    | `KINTONE_CUSTOMER_API_TOKEN` | 得意先マスタのAPIトークン | `...` |
    | `KINTONE_STAFF_APP_ID` | 営業担当者マスタのアプリID | `103` |
    | `KINTONE_STAFF_API_TOKEN` | 営業担当者マスタのAPIトークン | `...` |
    | `RAILS_MASTER_KEY` | Railsのマスターキー (Prod用) | |
    | `DATABASE_URL` | DB接続文字列 (Prod用, Render等で自動設定) | |

    ※ これらの設定は `config/initializers/kintone.rb` で読み込まれます。

5.  **ローカルサーバーの起動**
    ```bash
    bin/dev
    ```
    ブラウザで `http://localhost:3000` にアクセスします。

## 4. デプロイ手順 (Render)
本システムは Render.com の Blueprint 機能を使用しており、GitHub の `main` ブランチへのプッシュを検知して自動的にデプロイされます。

*   **設定ファイル**: `render.yaml`
*   **ビルドスクリプト**: `bin/render-build.sh` (アセットのコンパイル、DBマイグレーションを実行)

### 手動デプロイが必要な場合
Render のダッシュボードから `Manual Deploy` を実行してください。

## 5. Kintone連携について
本システムは Kintone アプリをマスタデータおよびデータ保存先として利用しています。

### 関連するKintoneアプリ
*   **見積アプリ**: 見積データの保存先
*   **商品マスタ**: 商品情報の参照元
*   **得意先マスタ**: 顧客情報の参照元

### 連携の仕組み
*   **データ取得 (GET)**: 商品検索時や見積一覧表示時に API 経由で取得。
*   **データ登録 (POST/PUT)**: 見積保存時に Kintone にデータを送信。
*   **認証**: APIトークンを使用（環境変数で管理）。

### 印刷機能
見積書の印刷は本システム上ではなく、データ連携された Kintone 上で行います。
*   **アカウント**: 営業共有アカウント (`saikai5555`)

## 6. ディレクトリ構造のポイント
*   `app/services/kintone/`: Kintone API との通信ロジックが格納されています。
*   `app/javascript/controllers/`: フロントエンドの動的制御（スキャナー入力制御、計算ロジック）などの Stimulus コントローラがあります。
*   `USER_MANUAL.md` / `USER_MANUAL.html`: 利用者向けのマニュアルです。

## 7. トラブルシューティング
*   **Kintoneデータが反映されない**: `bin/rails console` で `Kintone::Client` 等を用いてAPI疎通確認を行ってください。
*   **デプロイ失敗**: Render の Dashboard で Logs を確認してください。マイグレーションエラーなどが一般的です。
