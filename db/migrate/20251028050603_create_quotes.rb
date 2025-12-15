class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.string :customer_name
      t.date :date
      t.integer :total

      t.timestamps
    end
  end
end
