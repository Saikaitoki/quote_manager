# verify_stock_logic.rb

# 1. Mock the Service
module Kintone
  class ProductReservationService
    def initialize(quote)
      @quote = quote
    end

    def update_reservation!(old_items:, new_items:)
      puts "\n"
      puts "====== [Mock] ProductReservationService#update_reservation! ======"
      puts "Quote ID: #{@quote.id}"
      puts "OLD Items (Previous State): #{old_items.inspect}"
      puts "NEW Items (Current State) : #{new_items.inspect}"
      puts "=================================================================="
      puts "\n"
    end
  end

  class QuoteSyncService
    def initialize(quote); end
    def sync!; end
    def delete!; end
  end
end

puts "\n\n*********************************************************"
puts "          STARTING STOCK LOGIC VERIFICATION"
puts "*********************************************************\n"

# 2. Cleanup
Quote.where(customer_name: "TEST_VERIFY").destroy_all

# 3. Scenario A: Create New Quote
puts "\n>>> [Action] Creating new quote (A001: 10, B002: 5)..."
quote = Quote.new(
  customer_name: "TEST_VERIFY",
  created_on: Date.today,
  status: "pending"
)
quote.items.build(product_cd: "A001", quantity: 10, rate: 100, product_name: "TestA")
quote.items.build(product_cd: "B002", quantity: 5,  rate: 100, product_name: "TestB")
quote.save!

# 4. Scenario B: Update Quote (Change Quantity)
puts "\n>>> [Action] Updating quote (A001: 10->15, B002: 5->Delete)..."

# ★ Fix: Load items from the instance we just saved to ensure identity map consistency
item_a = quote.items.find { |i| i.product_cd == "A001" }
item_a.quantity = 15

item_b = quote.items.find { |i| i.product_cd == "B002" }
item_b.mark_for_destruction

quote.save!

# 5. Scenario C: Delete Quote
puts "\n>>> [Action] Deleting quote..."
quote.destroy!

puts "\n*********************************************************"
puts "          VERIFICATION FINISHED"
puts "*********************************************************\n\n"
