class AddRateColumnsToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :rate_proper, :integer
    add_column :quotes, :rate_kurashino, :integer
    add_column :quotes, :rate_common, :integer
    add_column :quotes, :rate_essence, :integer
    add_column :quotes, :rate_porcelains, :integer
    add_column :quotes, :rate_f_symbol, :integer
    add_column :quotes, :rate_h_symbol, :integer
  end
end
