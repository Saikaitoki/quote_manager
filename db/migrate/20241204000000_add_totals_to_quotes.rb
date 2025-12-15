# db/migrate/20241204000000_add_totals_to_quotes.rb

class AddTotalsToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :subtotal, :integer, null: false, default: 0
  end
end
