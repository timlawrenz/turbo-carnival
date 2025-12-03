# frozen_string_literal: true

namespace :personas do
  desc "Import content pillars from fluffy-train for Sarah persona"
  task import_pillars: :environment do
    puts "Importing content pillars from fluffy-train..."
    
    # Find Sarah in turbo-carnival
    sarah = Persona.find_by(name: "Sarah")
    unless sarah
      puts "❌ Sarah persona not found in turbo-carnival. Run personas:import_sarah first."
      exit 1
    end
    
    puts "✅ Found Sarah (ID: #{sarah.id})"
    
    # Query fluffy-train database directly
    begin
      result = ActiveRecord::Base.connection.execute(<<-SQL)
        SELECT 
          cp.id, cp.name, cp.description, cp.weight, cp.active,
          cp.start_date, cp.end_date, cp.guidelines, 
          cp.target_posts_per_week, cp.priority, cp.created_at
        FROM fluffy_train_development.content_pillars cp
        JOIN fluffy_train_development.personas p ON cp.persona_id = p.id
        WHERE p.name = 'Sarah'
        ORDER BY cp.priority DESC, cp.weight DESC
      SQL
      
      if result.count == 0
        puts "⚠️  No content pillars found for Sarah in fluffy-train"
        puts "Creating sample pillar for testing..."
        
        pillar = sarah.content_pillars.create!(
          name: "Sample Content",
          description: "Sample pillar for testing",
          weight: 100,
          priority: 3,
          active: true
        )
        puts "✅ Created sample pillar: #{pillar.name}"
        exit 0
      end
      
      imported_count = 0
      skipped_count = 0
      
      result.each do |row|
        # Check if pillar already exists
        existing = sarah.content_pillars.find_by(name: row['name'])
        if existing
          puts "⏭️  Skipping '#{row['name']}' (already exists)"
          skipped_count += 1
          next
        end
        
        # Create pillar in turbo-carnival
        pillar = sarah.content_pillars.create!(
          name: row['name'],
          description: row['description'],
          weight: row['weight'],
          active: row['active'],
          start_date: row['start_date'],
          end_date: row['end_date'],
          guidelines: row['guidelines'] || {},
          target_posts_per_week: row['target_posts_per_week'],
          priority: row['priority'] || 3
        )
        
        puts "✅ Imported: #{pillar.name} (#{pillar.weight}%, priority: #{pillar.priority})"
        imported_count += 1
      end
      
      puts ""
      puts "=" * 50
      puts "Import Summary:"
      puts "  Imported: #{imported_count}"
      puts "  Skipped: #{skipped_count}"
      puts "  Total in fluffy-train: #{result.count}"
      puts "  Total in turbo-carnival: #{sarah.content_pillars.count}"
      puts "=" * 50
      
    rescue ActiveRecord::StatementInvalid => e
      puts "⚠️  Could not query fluffy-train database: #{e.message}"
      puts ""
      puts "This is expected if:"
      puts "  - fluffy-train uses a different database name"
      puts "  - Database is not accessible"
      puts ""
      puts "Creating sample pillar for testing instead..."
      
      unless sarah.content_pillars.exists?
        pillar = sarah.content_pillars.create!(
          name: "Sample Content",
          description: "Sample pillar for testing",
          weight: 100,
          priority: 3,
          active: true
        )
        puts "✅ Created sample pillar: #{pillar.name}"
      else
        puts "✅ Sarah already has #{sarah.content_pillars.count} pillar(s)"
      end
    end
  end
end
