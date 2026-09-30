namespace :billetto do
  desc "Immediately import events from Billetto "
  task import: :environment do
    puts "Starting Billetto event ingestion..."
    begin
      BillettoIngestionJob.perform_now
      puts "Successfully imported #{Event.count} events."
    rescue => e
      puts "Error importing events: #{e.message}"
      exit 1
    end
  end
end
