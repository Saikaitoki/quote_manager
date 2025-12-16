# debug_deletion.rb
Rails.logger = Logger.new(STDOUT)
Rails.logger.level = :info

# Create a dummy quote to test deletion
q = Quote.new(
  customer_code: "99999", # Valid dummy?
  customer_name: "DeletionTest",
  created_on: Date.today,
  staff_code: "111",
  staff_name: "Tester"
)
q.items.build(
  product_cd: "DUMMY",
  product_name: "Test Item",
  quantity: 1,
  rate: 100,
  upper_price: 1000
)

puts ">>> Saving Quote..."
if q.save
  puts ">>> Saved. ID: #{q.id}"
  # Sync is async? No, based on code it is sync_to_kintone_later call is synchronous service.
  # But let's reload to be sure we have kintone ID
  q.reload
  puts ">>> Kintone ID: #{q.kintone_record_id}"

  if q.kintone_record_id.present?
    puts ">>> Destroying Quote..."
    q.destroy
    puts ">>> Destroyed."
  else
    puts ">>> Failed to get Kintone ID. Sync might have failed."
  end
else
  puts ">>> Failed to save: #{q.errors.full_messages}"
end
