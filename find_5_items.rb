quote = Quote.all.sort_by(&:created_at).reverse.find { |q| q.items.count == 5 }

unless quote
  puts "No quote with 5 items found."
  exit
end

puts "Found Quote ID: #{quote.id}"
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
