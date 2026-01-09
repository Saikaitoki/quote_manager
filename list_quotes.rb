quotes = Quote.order(created_at: :desc).limit(10)
quotes.each do |q|
  puts "ID: #{q.id} | Kintone ID: #{q.kintone_record_id} | Created: #{q.created_at}"
end
