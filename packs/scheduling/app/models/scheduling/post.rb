# frozen_string_literal: true

module Scheduling
  class Post < ApplicationRecord
    self.table_name = 'scheduling_posts'

    belongs_to :photo, class_name: 'ContentPillars::Photo', optional: true
    belongs_to :persona, class_name: 'Persona'
    belongs_to :content_suggestion, optional: true
    belongs_to :pipeline_run, optional: true

    validates :photo, presence: true, if: :ready_to_post?

    scope :posted, -> { where(status: 'posted') }
    scope :with_strategy, ->(strategy_name) { where(strategy_name: strategy_name) }
    scope :awaiting_photo, -> { where(photo_id: nil) }
    scope :with_photo, -> { where.not(photo_id: nil) }

    state_machine :status, initial: :draft do
      state :draft           # Created, may or may not have image yet
      state :awaiting_image  # PipelineRun in progress
      state :ready           # Image linked, ready to schedule
      state :scheduled       # Scheduled for future posting
      state :posting         # Currently posting
      state :posted          # Successfully posted
      state :failed          # Posting failed

      event :start_image_generation do
        transition draft: :awaiting_image
      end

      event :image_ready do
        transition awaiting_image: :ready
      end

      event :schedule do
        transition [:draft, :ready] => :scheduled
      end

      event :start_posting do
        transition [:draft, :scheduled] => :posting
      end

      event :mark_as_posted do
        transition %i[scheduled posting] => :posted
      end

      event :mark_as_failed do
        transition %i[scheduled posting] => :failed
      end
    end

    def ready_to_post?
      %w[scheduled posting posted].include?(status)
    end

    def image_promise_fulfilled?
      photo_id.present?
    end
  end
end
