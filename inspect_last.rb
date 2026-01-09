quote = Quote.last
unless quote
  puts "No quotes found."
  exit
end

puts "Inspecting Last Quote: ID #{quote.id} (Kintone ID: #{quote.kintone_record_id})"

puts "\n--- Items (Raw DB Order) ---"
# Created_at precision is important
quote.items.each do |i|
  puts "ID: #{i.id} | Created: #{i.created_at.to_f} | Name: #{i.product_name}"
end

puts "\n--- Sorting Simulation (View Logic) ---"
sorted = quote.items.to_a.sort { |a, b| 
  comp = (b.created_at || Time.current) <=> (a.created_at || Time.current)
  comp == 0 ? (b.id || Float::INFINITY) <=> (a.id || Float::INFINITY) : comp 
}

sorted.each do |i|
  puts "ID: #{i.id} | Name: #{i.product_name}"
end
