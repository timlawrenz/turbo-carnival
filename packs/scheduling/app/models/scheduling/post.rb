# frozen_string_literal: true

module Scheduling
  class Post < ApplicationRecord
    self.table_name = 'scheduling_posts'

    belongs_to :photo, class_name: 'ContentPillars::Photo'
    belongs_to :persona, class_name: 'Persona'

    scope :posted, -> { where(status: 'posted') }
    scope :with_strategy, ->(strategy_name) { where(strategy_name: strategy_name) }

    state_machine :status, initial: :draft do
      state :draft
      state :scheduled
      state :posting
      state :posted
      state :failed

      event :schedule do
        transition draft: :scheduled
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
  end
end
