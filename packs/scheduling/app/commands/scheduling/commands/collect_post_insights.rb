# frozen_string_literal: true

module Scheduling
  module Commands
    class CollectPostInsights < GLCommand::Callable
      BASE_URL = "https://graph.facebook.com/v20.0"

      def call
        posts = posts_needing_insights
        return if posts.empty?

        collected = 0
        posts.find_each do |post|
          insights = fetch_insights(post)
          next unless insights

          post.update!(insights)
          collected += 1
        end

        Rails.logger.info("CollectPostInsights: updated #{collected} posts")
      end

      private

      def posts_needing_insights
        Scheduling::Post
          .where(persona_id: Persona.find_by(name: "Sarah")&.id)
          .where(status: "posted")
          .where.not(provider_post_id: nil)
          .where("posted_at < ?", 24.hours.ago)
          .where("insights_updated_at IS NULL OR insights_updated_at < ?", 6.hours.ago)
          .limit(25) # Instagram rate limit: 200 calls/hour
      end

      def fetch_insights(post)
        token = Rails.application.credentials.dig(:instagram, :access_token)
        media_id = post.provider_post_id

        return nil unless media_id && token

        conn = Faraday.new(url: BASE_URL) { |f| f.request :url_encoded; f.response :json }

        resp = conn.get("#{media_id}/insights") do |req|
          req.params["metric"] = "likes,comments,reach,saved,shares"
          req.params["access_token"] = token
        end

        return nil unless resp.status == 200

        data = resp.body["data"] || []
        metrics = data.each_with_object({}) { |m, h| h[m["name"]] = m["values"].first&.dig("value") || 0 }

        likes    = metrics["likes"] || 0
        comments = metrics["comments"] || 0
        reach    = metrics["reach"] || 1
        saved    = (metrics["saved"] || 0) + (metrics["shares"] || 0)

        engagement = reach.positive? ? ((likes + comments + saved).to_f / reach * 100).round(2) : 0

        {
          likes_count: likes,
          comments_count: comments,
          reach: reach,
          saved_count: saved,
          engagement_rate: engagement,
          insights_updated_at: Time.current
        }
      rescue Faraday::Error => e
        Rails.logger.warn("CollectPostInsights API error for post #{post.id}: #{e.message}")
        nil
      end
    end
  end
end
