item = QuoteItem.where("product_cd LIKE ?", "%00001%").order(created_at: :desc).first
unless item
  puts "Item Code 00001 not found"
  exit
end

quote = item.quote
puts "Found Quote ID: #{quote.id} (Kintone: #{quote.kintone_record_id})"
puts "Items for Quote #{quote.id}:"
quote.items.each do |i|
  puts "ID: #{i.id} | Code: #{i.product_cd} | Name: #{i.product_name} | Created: #{i.created_at.to_f}"
end

puts "\n--- Ruby Sort Result ---"
sorted = quote.items.to_a.sort { |a, b| 
  comp = (b.created_at || Time.now) <=> (a.created_at || Time.now)
  comp == 0 ? (b.id || Float::INFINITY) <=> (a.id || Float::INFINITY) : comp 
}
sorted.each do |i|
  puts "ID: #{i.id} | Code: #{i.product_cd}"
end
