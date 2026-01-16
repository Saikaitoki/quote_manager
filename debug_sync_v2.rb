# debug_sync_v2.rb

def find_quote(id)
  # 1. Try finding by Rails ID
  q = Quote.find_by(id: id)
  return q if q

  # 2. Try finding by Kintone Record ID (String or Integer)
  q = Quote.find_by(kintone_record_id: id.to_s)
  return q if q

  Quote.find_by(kintone_record_id: id.to_i)
end

target_id = 117
quote = find_quote(target_id)

unless quote
  puts "❌ Quote with ID or Kintone ID #{target_id} not found in THIS database."
  puts ""
  puts "⚠️ IMPORTANT:"
  puts "If you are seeing this record on the live website (Render), running this script LOCALLY will not find it."
  puts "The local database and production database are separate."
  puts "To check production data, run this script via Render Console."
  puts ""
  puts "Current Database Config:"
  puts ActiveRecord::Base.connection_db_config.configuration_hash
  exit
end

puts "=== Quote Info ==="
puts "Rails ID: #{quote.id}"
puts "Kintone Record ID: #{quote.kintone_record_id.inspect}"
puts "Status: #{quote.status} (should be 'synced')"
puts "Last Synced At: #{quote.synced_at}"
puts "Updated At: #{quote.updated_at}"
puts "Kintone Revision: #{quote.kintone_revision}"
puts "Items Count: #{quote.items.count}"
puts "=================="

puts "🚀 Starting manual sync..."

begin
  service = Kintone::QuoteSyncService.new(quote)
  service.sync!
  
  puts "✅ Sync completed successfully!"
  puts "New Revision: #{quote.kintone_revision}"
  puts "New Status: #{quote.status}"
rescue => e
  puts "❌ Sync FAILED!"
  puts "Error: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
end
