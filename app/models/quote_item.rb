# app/models/quote_item.rb
class QuoteItem < ApplicationRecord
  self.table_name = "items"

  belongs_to :quote

  alias_attribute :product_code,       :product_cd
  alias_attribute :product_name,       :product_name
  alias_attribute :sashihiki_jitsu,    :difference_actual
  alias_attribute :quantity,           :quantity
  alias_attribute :rate,               :rate
  alias_attribute :net_price,          :lower_price
  alias_attribute :amount,             :amount
  alias_attribute :list_price,         :upper_price
  alias_attribute :catalog_no,         :catalog_no
  alias_attribute :special_list_price, :special_upper_price
  alias_attribute :inner_qty,          :inner_box_count
  alias_attribute :page,               :page
  alias_attribute :row_no,             :row
  alias_attribute :packing,            :package
end
