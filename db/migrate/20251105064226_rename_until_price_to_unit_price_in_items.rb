class RenameUntilPriceToUnitPriceInItems < ActiveRecord::Migration[8.0]
  def change
    rename_column :items, :until_price, :unit_price
  end
end
