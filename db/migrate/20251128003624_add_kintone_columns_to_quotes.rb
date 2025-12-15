# db/migrate/xxxxxxxxxxxx_add_kintone_columns_to_quotes.rb
class AddKintoneColumnsToQuotes < ActiveRecord::Migration[7.1]
  def change
    add_column :quotes, :kintone_record_id, :string
    add_column :quotes, :kintone_revision, :integer
    add_index  :quotes, :kintone_record_id
  end
end
