class AddStockStatusToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :stock_status, :string, default: "secured", null: false
  end
end
