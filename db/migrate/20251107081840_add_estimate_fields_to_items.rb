class AddEstimateFieldsToItems < ActiveRecord::Migration[7.1]
  def change
    change_table :items, bulk: true do |t|
      t.string  :product_cd
      t.integer :difference_actual
      t.decimal :rate, precision: 5, scale: 2
      t.integer :lower_price
      t.integer :amount
      t.integer :upper_price
      t.string  :catalog_no
      t.integer :special_upper_price
      t.integer :inner_box_count
      t.string  :page
      t.string  :row
      t.string  :package
    end
  end
end
