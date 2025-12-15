class AddQuoteHeaderFields < ActiveRecord::Migration[7.1]
  def change
    add_column :quotes, :customer_code, :string
    add_column :quotes, :ship_to_name, :string
    add_column :quotes, :staff_code, :string
    add_column :quotes, :staff_name, :string
    add_column :quotes, :created_on, :date
    add_column :quotes, :note, :text
  end
end
