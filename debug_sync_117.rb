# debug_sync_117.rb
begin
  quote = Quote.find_by(id: 117)
  
  unless quote
    puts "❌ Quote with ID 117 not found in Rails DB."
    exit
  end

  puts "=== Quote Info ==="
  puts "ID: #{quote.id}"
  puts "Kintone Record ID: #{quote.kintone_record_id.inspect}"
  puts "Status: #{quote.status}"
  puts "Updated At: #{quote.updated_at}"
  puts "Items Count: #{quote.items.count}"
  puts "=================="

  if quote.kintone_record_id.blank?
    puts "⚠️ Kintone Record ID is missing. Sync will attempt to CREATE a new record."
  else
    puts "ℹ️ Kintone Record ID exists. Sync will attempt to UPDATE record ##{quote.kintone_record_id}."
  end

  puts "🚀 Starting manual sync..."
  
  # Initialize service and sync
  service = Kintone::QuoteSyncService.new(quote)
  service.sync!

  puts "✅ Sync completed successfully!"
  puts "Current Kintone Revision: #{quote.kintone_revision}"
  puts "Raw Payload: #{quote.raw_payload}"

rescue => e
  puts "❌ Sync FAILED!"
  puts "Error Class: #{e.class}"
  puts "Message: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(10)
end
