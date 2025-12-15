class Item < ApplicationRecord
  belongs_to :quote

  validates :product_cd, :product_name, presence: true
  validates :quantity, :lower_price, :upper_price, :amount, numericality: { allow_nil: true }

  before_save :calculate_amount

  private

  def calculate_amount
    self.amount = (quantity || 0) * (lower_price || 0)
  end
end
