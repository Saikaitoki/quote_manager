item = QuoteItem.where("product_name LIKE ?", "%00001%").order(created_at: :desc).first
unless item
  puts "Item 00001 not found"
  exit
end

quote = item.quote
puts "Found Quote ID: #{quote.id} (Kintone: #{quote.kintone_record_id})"
puts "Items:"
quote.items.each do |i|
  puts "ID: #{i.id} | Name: #{i.product_name} | Created: #{i.created_at.strftime('%H:%M:%S.%N')}"
end

puts "\n--- Ruby Sort Result ---"
sorted = quote.items.to_a.sort { |a, b| 
  comp = (b.created_at || Time.now) <=> (a.created_at || Time.now)
  comp == 0 ? (b.id || Float::INFINITY) <=> (a.id || Float::INFINITY) : comp 
}
sorted.each do |i|
  puts "ID: #{i.id} | Name: #{i.product_name}"
end
