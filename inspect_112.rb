# Find quote by ID 112 or Kintone ID 112
quote = Quote.find_by(id: 112) || Quote.where(kintone_record_id: "112").order(created_at: :desc).first

unless quote
  puts "Quote 112 not found"
  exit
end

puts "Quote ID: #{quote.id} (Kintone ID: #{quote.kintone_record_id})"

puts "\n--- Items (Raw DB Order) ---"
quote.items.each do |i|
  # Print high precision time
  puts "ID: #{i.id} | Created: #{i.created_at.strftime('%H:%M:%S.%N')} | Name: #{i.product_name}"
end

puts "\n--- Sorting Simulation (Ruby Sort used in View) ---"
sorted = quote.items.to_a.sort { |a, b| 
  comp = (b.created_at || Time.current) <=> (a.created_at || Time.current)
  comp == 0 ? (b.id || Float::INFINITY) <=> (a.id || Float::INFINITY) : comp 
}

sorted.each do |i|
  puts "ID: #{i.id} | Name: #{i.product_name}"
end
