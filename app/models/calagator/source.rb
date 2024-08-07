# frozen_string_literal: true

# == Schema Information
#
# Table name: sources
#
#  id          :integer          not null, primary key
#  imported_at :datetime
#  title       :string
#  url         :string
#  created_at  :datetime
#  updated_at  :datetime
#

# == Source
#
# A model that represents a source of events data, such as feeds for hCal, iCal, etc.
require "paper_trail"

module Calagator
  class Source < Calagator::ApplicationRecord
    self.table_name = "sources"

    validate :assert_url

    has_many :events
    has_many :venues

    scope :listing, -> { order("created_at DESC") }

    has_paper_trail

    # Create events for this source. Returns the events created. URL must be set
    # for this source for this to work.
    def create_events!
      save!
      to_events
        .select(&:valid?)
        .reject(&:old?)
        .each(&:save!)
        .tap { touch(:imported_at) }
    end

    # Normalize the URL.
    def url=(value)
      url = URI.parse(value.strip)
      unless %w[http https ftp].include?(url.scheme) || url.scheme.nil?
        url.scheme = "http"
      end
      self[:url] = url.scheme.nil? ? "http://" + value.strip : url.to_s
    rescue URI::InvalidURIError
      false
    end

    # Returns an Array of Event objects that were read from this source.
    def to_events
      raise ActiveRecord::RecordInvalid, self unless valid?
      Source::Parser.to_events(url: url, source: self)
    end

    def importer
      Importer.new(self)
    end

    # Return the name of the source, which can be its title or URL.
    def name
      [title, url].detect(&:present?)
    end

    private

    # Ensure that the URL for this source is valid.
    def assert_url
      URI.parse(url)
    rescue URI::InvalidURIError
      errors.add :url, "has invalid format"
      false
    end
  end
end
