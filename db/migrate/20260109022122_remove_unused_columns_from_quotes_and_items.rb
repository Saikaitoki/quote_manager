class RemoveUnusedColumnsFromQuotesAndItems < ActiveRecord::Migration[8.1]
  def change
    remove_column :quotes, :date, :date
    remove_column :quotes, :total, :integer
    remove_column :items, :unit_price, :integer
  end
end
