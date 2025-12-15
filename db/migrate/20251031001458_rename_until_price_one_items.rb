class RenameUntilPriceOneItems < ActiveRecord::Migration[8.1]
  def change
    # もしカラムが存在していればリネーム（存在しなければスキップ）
    if column_exists?(:items, :until_price)
      rename_column :items, :until_price, :unit_price
    end
  end
end
