class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :quote, null: false, foreign_key: true
      t.string :product_name
      t.integer :unit_price
      t.integer :quantity

      t.timestamps
    end
  end
end
