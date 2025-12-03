# frozen_string_literal: true

namespace :personas do
  desc "Import content pillars from fluffy-train for Sarah persona"
  task import_pillars: :environment do
    puts "Importing content pillars from fluffy-train..."
    
    # Find Sarah in turbo-carnival (case-insensitive)
    sarah = Persona.find_by("LOWER(name) = ?", "sarah")
    unless sarah
      puts "❌ Sarah persona not found in turbo-carnival. Run personas:import_sarah first."
      exit 1
    end
    
    puts "✅ Found Sarah (ID: #{sarah.id}, name: '#{sarah.name}')"
    
    # Establish connection to fluffy-train database
    fluffy_config = {
      adapter: 'postgresql',
      encoding: 'unicode',
      pool: 5,
      database: 'fluffy_train_development',
      username: 'tim',
      host: 'localhost'
    }
    
    begin
      # Create a dedicated connection
      fluffy_conn = ActiveRecord::Base.establish_connection(fluffy_config).connection
      
      # Query Sarah's persona data
      persona_result = fluffy_conn.execute(<<-SQL)
        SELECT id, name, caption_config, hashtag_strategy
        FROM personas
        WHERE LOWER(name) = 'sarah'
        LIMIT 1
      SQL
      
      if persona_result.count > 0
        fluffy_sarah = persona_result.first
        puts "📋 Updating Sarah's caption_config and hashtag_strategy from fluffy-train..."
        
        # Update Sarah in turbo-carnival with fluffy-train data
        if fluffy_sarah['caption_config']
          sarah[:caption_config] = fluffy_sarah['caption_config']
        end
        
        if fluffy_sarah['hashtag_strategy']
          sarah[:hashtag_strategy] = fluffy_sarah['hashtag_strategy']
        end
        
        sarah.save!
        puts "✅ Updated Sarah's persona data"
      end
      
      # Query content pillars
      result = fluffy_conn.execute(<<-SQL)
        SELECT 
          cp.id, cp.name, cp.description, cp.weight, cp.active,
          cp.start_date, cp.end_date, cp.guidelines, 
          cp.target_posts_per_week, cp.priority, cp.created_at
        FROM content_pillars cp
        JOIN personas p ON cp.persona_id = p.id
        WHERE LOWER(p.name) = 'sarah'
        ORDER BY cp.priority DESC, cp.weight DESC
      SQL
      
      # Restore turbo-carnival connection
      ActiveRecord::Base.establish_connection(:development)
      
      if result.count == 0
        puts "⚠️  No content pillars found for sarah in fluffy-train"
        puts "Creating sample pillar for testing..."
        
        unless sarah.content_pillars.exists?
          pillar = sarah.content_pillars.create!(
            name: "Sample Content",
            description: "Sample pillar for testing",
            weight: 100,
            priority: 3,
            active: true
          )
          puts "✅ Created sample pillar: #{pillar.name}"
        end
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
      puts "=" * 60
      puts "Import Summary:"
      puts "  Imported pillars: #{imported_count}"
      puts "  Skipped: #{skipped_count}"
      puts "  Total in fluffy-train: #{result.count}"
      puts "  Total in turbo-carnival: #{sarah.content_pillars.count}"
      puts "  Total weight: #{sarah.content_pillars.active.sum(:weight)}%"
      puts "=" * 60
      
    rescue => e
      # Restore connection on error
      ActiveRecord::Base.establish_connection(:development)
      
      puts "⚠️  Could not connect to fluffy-train: #{e.message}"
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
