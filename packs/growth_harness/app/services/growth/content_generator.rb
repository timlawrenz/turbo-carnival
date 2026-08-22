# frozen_string_literal: true

module Growth
  # Generates FRESH content by rendering the turbo-one-step workflow, imports
  # the output as a photo, captions it, and schedules it. This replaces the old
  # cadence path that merely *reused* stale library photos.
  class ContentGenerator
    PIPELINE_NAME = 'turbo-one-step'
    COMFYUI_OUTPUT = '/mnt/fscache/essdee/ComfyUI/output'
    POLL_INTERVAL = 20
    MAX_POLLS = 60 # ~20 min (renders are slow + OOM-retry can add time)

    attr_reader :goal

    def initialize(goal:, pillar: nil)
      @goal = goal
      @pillar = pillar || default_pillar
    end

    # Generate one fresh render + caption + scheduled post.
    def generate_one(offset_days: 1)
      pipeline = Pipeline.find_by(name: PIPELINE_NAME)
      unless pipeline
        return { success: false, error: "pipeline #{PIPELINE_NAME} not found" }
      end

      run = PipelineRun.create!(
        pipeline: pipeline,
        persona: persona,
        content_pillar: @pillar,
        name: "gen-#{Time.now.to_i}",
        prompt: build_prompt,
        target_folder: "fresh/#{@pillar&.name&.parameterize || 'gen'}",
        status: 'pending'
      )

      step = pipeline.pipeline_steps.order(:order).first
      payload = BuildJobPayload.call!(pipeline_step: step, pipeline_run: run)
      submit = SubmitJob.call(job_payload: payload.job_payload, pipeline_step: step, pipeline_run: run)
      unless submit.success?
        return { success: false, error: submit.full_error_message, run_id: run.id }
      end

      comfyjob = submit.comfyui_job
      image_path = poll_for_image(comfyjob.comfyui_job_id)
      unless image_path
        return { success: false, error: 'render timed out or produced no image', run_id: run.id, comfyjob_id: comfyjob.id }
      end

      # NSFW gate: a third-party ViT classifier (Falconsai/nsfw_image_detection)
      # must accept the render before it can enter the photo library / queue.
      gate = Growth::NsfwGate.new.call(image_path: image_path)
      unless gate.safe
        log_rejection(image_path, gate)
        return {
          success: false,
          error: "nsfw_rejected (#{gate.error || "label=#{gate.label} score=#{gate.nsfw_score}"})",
          run_id: run.id, comfyjob_id: comfyjob.id, image_path: image_path
        }
      end

      # Import the fresh render as a content photo
      photo = import_photo(image_path, run)
      return { success: false, error: 'photo import failed' } unless photo

      # Caption it
      cap = PostAutomation::GenerateCaption.call(photo: photo, persona: persona, pillar: @pillar)
      caption = cap.success? ? cap.caption : "Fresh look ✨"

      # Schedule it
      sched = Scheduling::Post.create!(
        persona: persona,
        photo: photo,
        caption: caption,
        status: 'scheduled',
        scheduled_at: Time.current + offset_days.days,
        optimal_time_calculated: Time.current + offset_days.days,
        strategy_name: 'turbo-one-step'
      )

      { success: true, post_id: sched.id, photo_id: photo.id, image_path: image_path, run_id: run.id }
    end

    private

    def persona
      goal.persona
    end

    def default_pillar
      persona.content_pillars.current.order(weight: :desc).first
    end

    def build_prompt
      base = 'A photorealistic portrait of Sarah, warm natural light, softly glowing skin, authentic candid expression.'
      scene = [
        'casual streetwear, golden hour sidewalk cafe, shallow depth of field',
        'cozy knit sweater, sunlit window, morning tea, gentle smile',
        'summer dress, flower field, soft bokeh, candid laugh',
        'elegant evening look, city lights bokeh, confident gaze',
        'beach day, loose waves, bright airy light, carefree'
      ]
      "#{base} #{scene.sample}."
    end

    def poll_for_image(comfyui_job_id)
      client = ComfyuiClient.new
      MAX_POLLS.times do |i|
        begin
          s = client.get_job_status(comfyui_job_id)
        rescue StandardError => e
          sleep POLL_INTERVAL
          next
        end

        if s[:status] == 'completed'
          node = s[:output] || {}
          img = nil
          node.each do |_nid, payload|
            # get_job_status deep_symbolizes keys, but be tolerant of both
            p = payload.is_a?(Hash) ? payload : {}
            images = p[:images] || p['images']
            next unless images.present?

            img = images.first
            break
          end
          return nil unless img

          filename = img[:filename] || img['filename']
          subfolder = img[:subfolder] || img['subfolder']
          return File.join(COMFYUI_OUTPUT, subfolder.to_s, filename) if filename
        elsif s[:status] == 'failed'
          Rails.logger.warn("Growth::ContentGenerator render failed: #{s[:error]}")
          return nil
        end
        # not_found → still queued/executing; keep polling
        sleep POLL_INTERVAL
      end
      nil
    end

    # Record an auditable rejection decision and warn in the log. The image
    # stays in ComfyUI's output tree (Tim's playground) but never enters the
    # photo library or queue.
    def log_rejection(image_path, gate)
      reason = if gate.error
                 "nsfw gate error: #{gate.error}"
               else
                 "nsfw rejected by #{gate.label} score=#{gate.nsfw_score} (threshold=#{gate.threshold})"
               end
      Growth::Decision.create!(
        goal: goal,
        action: 'nsfw_rejected',
        reason: "#{reason} | #{image_path}",
        decided_at: Time.current
      )
      Rails.logger.warn("Growth::ContentGenerator #{reason} | #{image_path}")
    rescue StandardError => e
      Rails.logger.error("Growth::ContentGenerator could not log rejection: #{e.message}")
    end

    def import_photo(image_path, run)
      return nil unless image_path && File.exist?(image_path)

      photo = ContentPillars::Photo.find_by(path: image_path)
      return photo if photo

      ContentPillars::Photo.create!(
        persona: persona,
        path: image_path,
        content_pillar: @pillar,
        image_candidate: nil
      )
    rescue ActiveRecord::RecordInvalid
      ContentPillars::Photo.find_by(path: image_path)
    end
  end
end