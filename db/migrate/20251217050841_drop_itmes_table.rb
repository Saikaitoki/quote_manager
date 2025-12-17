class DropItmesTable < ActiveRecord::Migration[8.1]
  def change
    drop_table :itmes do |t|
      t.string :product_name
      t.integer :quantity
      t.integer :quote_id, null: false
      t.integer :until_price
      t.timestamps
      t.index :quote_id
    end
  end
end
