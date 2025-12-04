# frozen_string_literal: true

class GapAnalysisService
  def initialize(persona)
    @persona = persona
  end

  def analyze!
    coverage_data = calculate_coverage
    recommendations = generate_recommendations(coverage_data)

    gap_analysis = GapAnalysis.create!(
      persona: @persona,
      analyzed_at: Time.current,
      coverage_data: coverage_data,
      recommendations: recommendations
    )

    create_suggestions(gap_analysis, recommendations)
    
    gap_analysis
  end

  private

  def calculate_coverage
    pillars = @persona.content_pillars.includes(clusters: :photos)
    
    pillars.map do |pillar|
      clusters_data = pillar.clusters.map do |cluster|
        {
          id: cluster.id,
          name: cluster.name,
          photo_count: cluster.photos.count,
          last_photo_at: cluster.photos.maximum(:created_at),
          existing_prompts: cluster.photos.joins(:image_candidate)
                                   .joins('INNER JOIN pipeline_runs ON image_candidates.pipeline_run_id = pipeline_runs.id')
                                   .pluck('pipeline_runs.prompt')
                                   .compact.uniq
        }
      end

      {
        pillar_id: pillar.id,
        pillar_name: pillar.name,
        total_clusters: pillar.clusters.count,
        total_photos: clusters_data.sum { |c| c[:photo_count] },
        clusters: clusters_data,
        coverage_score: calculate_pillar_score(clusters_data)
      }
    end
  end

  def calculate_pillar_score(clusters_data)
    return 0 if clusters_data.empty?
    
    total_photos = clusters_data.sum { |c| c[:photo_count] }
    cluster_balance = clusters_data.count { |c| c[:photo_count] > 0 }.to_f / clusters_data.size
    recency_score = calculate_recency_score(clusters_data)
    
    (total_photos * 0.4 + cluster_balance * 100 * 0.4 + recency_score * 0.2).round(2)
  end

  def calculate_recency_score(clusters_data)
    recent_photos = clusters_data.count do |c|
      c[:last_photo_at] && c[:last_photo_at] > 30.days.ago
    end
    
    return 100 if clusters_data.empty?
    (recent_photos.to_f / clusters_data.size * 100).round(2)
  end

  def generate_recommendations(coverage_data)
    sorted_pillars = coverage_data.sort_by { |p| p[:coverage_score] }
    
    sorted_pillars.first(3).flat_map do |pillar_data|
      generate_pillar_recommendations(pillar_data)
    end
  end

  def generate_pillar_recommendations(pillar_data)
    pillar = @persona.content_pillars.find(pillar_data[:pillar_id])
    
    underserved_clusters = pillar_data[:clusters]
      .sort_by { |c| [c[:photo_count], c[:last_photo_at] || Time.at(0)] }
      .first(2)
    
    underserved_clusters.map do |cluster_data|
      generate_cluster_recommendation(pillar, cluster_data)
    end
  end

  def generate_cluster_recommendation(pillar, cluster_data)
    cluster = pillar.clusters.find(cluster_data[:id])
    
    {
      pillar_id: pillar.id,
      pillar_name: pillar.name,
      cluster_id: cluster.id,
      cluster_name: cluster.name,
      current_photo_count: cluster_data[:photo_count],
      reason: generate_reason(cluster_data),
      existing_prompts: cluster_data[:existing_prompts]
    }
  end

  def generate_reason(cluster_data)
    if cluster_data[:photo_count].zero?
      "No content yet for this cluster"
    elsif cluster_data[:last_photo_at].nil? || cluster_data[:last_photo_at] < 60.days.ago
      "Content is outdated (last photo: #{cluster_data[:last_photo_at]&.to_date || 'never'})"
    else
      "Low coverage compared to other clusters"
    end
  end

  def create_suggestions(gap_analysis, recommendations)
    recommendations.each do |rec|
      cluster = Clustering::Cluster.find(rec[:cluster_id])
      pillar = ContentPillar.find(rec[:pillar_id])
      
      ai_content = generate_ai_suggestion(pillar, cluster, rec[:existing_prompts])
      
      ContentSuggestion.create!(
        gap_analysis: gap_analysis,
        content_pillar: pillar,
        title: ai_content[:title],
        description: ai_content[:description],
        prompt_data: {
          prompt: ai_content[:prompt],
          cluster_id: cluster.id,
          cluster_name: cluster.name,
          reason: rec[:reason],
          existing_prompts: rec[:existing_prompts]
        },
        status: 'pending'
      )
    end
  end

  def generate_ai_suggestion(pillar, cluster, existing_prompts)
    context = {
      persona_name: @persona.name,
      persona_style: @persona.caption_config&.[]('voice_attributes') || [],
      persona_topics: @persona.caption_config&.[]('topics') || [],
      pillar_name: pillar.name,
      pillar_description: pillar.description,
      cluster_name: cluster.name,
      cluster_ai_prompt: cluster.ai_prompt,
      existing_prompts: existing_prompts,
      existing_prompts_count: existing_prompts.size
    }
    
    call_openai_api(context)
  end

  def call_openai_api(context)
    client = OpenAI::Client.new(access_token: Rails.application.credentials.dig(:openai, :api_key))
    
    prompt = build_ai_prompt_text(context)
    
    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          { role: "system", content: "You are a creative content strategist helping generate unique Instagram photo concepts." },
          { role: "user", content: prompt }
        ],
        temperature: 0.8
      }
    )
    
    content = response.dig("choices", 0, "message", "content")
    parse_ai_response(content)
  rescue => e
    Rails.logger.error("OpenAI API error: #{e.message}")
    {
      title: "Manual suggestion needed",
      description: "AI unavailable. Please create content for #{context[:cluster_name]}.",
      prompt: "#{context[:cluster_name]} - #{context[:pillar_name]}"
    }
  end

  def build_ai_prompt_text(context)
    <<~PROMPT
      Generate a unique Instagram photo concept for persona "#{context[:persona_name]}".
      
      Persona style: #{context[:persona_style].join(', ')}
      Persona topics: #{context[:persona_topics].join(', ')}
      
      Content Pillar: #{context[:pillar_name]}
      #{context[:pillar_description]}
      
      Content Cluster: #{context[:cluster_name]}
      #{context[:cluster_ai_prompt]}
      
      IMPORTANT: We already have #{context[:existing_prompts_count]} photos with these prompts:
      #{context[:existing_prompts].map { |p| "- #{p}" }.join("\n")}
      
      Please suggest a DIFFERENT, UNIQUE photo concept that:
      1. Fits the persona's style and topics
      2. Aligns with the pillar "#{context[:pillar_name]}"
      3. Matches the cluster "#{context[:cluster_name]}"
      4. Is COMPLETELY DIFFERENT from existing prompts (avoid repetition)
      5. Is specific and actionable for AI image generation
      
      Provide:
      1. A short title (2-5 words)
      2. A detailed description (2-3 sentences)
      3. A specific AI image generation prompt
      
      Format as JSON:
      {
        "title": "...",
        "description": "...",
        "prompt": "..."
      }
    PROMPT
  end

  def parse_ai_response(response)
    json_match = response.match(/\{.*\}/m)
    return { title: "AI Suggestion", description: response, prompt: response } unless json_match
    
    JSON.parse(json_match[0])
  rescue JSON::ParserError
    { title: "AI Suggestion", description: response, prompt: response }
  end
end
