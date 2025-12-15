class AddKintoneFieldsToQuotes < ActiveRecord::Migration[8.1]
  def change
    # ---- カラム追加（存在していなければ） ----
    add_column :quotes, :kintone_record_id, :string \
      unless column_exists?(:quotes, :kintone_record_id)

    add_column :quotes, :customer_code, :string \
      unless column_exists?(:quotes, :customer_code)
    add_column :quotes, :staff_code, :string \
      unless column_exists?(:quotes, :staff_code)
    add_column :quotes, :staff_name, :string \
      unless column_exists?(:quotes, :staff_name)

    add_column :quotes, :created_on, :date \
      unless column_exists?(:quotes, :created_on)

    add_column :quotes, :subtotal, :integer, default: 0, null: false \
      unless column_exists?(:quotes, :subtotal)

    add_column :quotes, :status, :string, default: "pending", null: false \
      unless column_exists?(:quotes, :status)
    add_column :quotes, :synced_at, :datetime \
      unless column_exists?(:quotes, :synced_at)

    # SQLite なので jsonb はやめて text にしておく
    add_column :quotes, :raw_payload, :text \
      unless column_exists?(:quotes, :raw_payload)

    # ---- インデックスも存在チェック付きで ----
    add_index :quotes, :kintone_record_id, unique: true \
      unless index_exists?(:quotes, :kintone_record_id)

    add_index :quotes, :created_on \
      unless index_exists?(:quotes, :created_on)
    add_index :quotes, :status \
      unless index_exists?(:quotes, :status)
  end
end
