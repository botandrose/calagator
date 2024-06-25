# frozen_string_literal: true

require "calagator/vcalendar"

# == Source::Parser::Ical
#
# Reads iCalendar events.
#
# Example:
#   events = Source::Parser::Ical.to_events('http://appendix.23ae.com/calendars/AlternateHolidays.ics')
#
# Sample sources:
#   webcal://appendix.23ae.com/calendars/AlternateHolidays.ics
#   http://appendix.23ae.com/calendars/AlternateHolidays.ics
module Calagator
  class Source::Parser::Ical < Source::Parser
    self.label = :iCalendar

    # Override Source::Parser.read_url to handle "webcal" scheme addresses.
    def self.read_url(url)
      url = url.gsub(/^webcal:/, "http:")
      super
    end

    def to_events
      return false unless vcalendars

      current_vevents = vcalendars.flat_map(&:vevents).reject(&:old?)
      current_events = current_vevents.map { |vevent| to_event(vevent) }
      dedup(current_events)
    end

    private

    def vcalendars
      @vcalendars ||= VCalendar.parse(raw_ical)
    end

    def raw_ical
      self.class.read_url(url)
    end

    def to_event(vevent)
      attrs = EventMapper.new(vevent).to_event_attributes
      event = source.events.where(uid: attrs[:uid]).first_or_initialize
      event.attributes = attrs
      event.venue || event.build_venue
      event.venue.update! VenueMapper.new(vevent.vvenue, vevent.location).to_venue_attributes
      event
    end

    def dedup(events)
      events.map do |event|
        event.venue = venue_or_duplicate(event.venue) if event.venue
        event
      end.uniq
    end

    # Converts a VEvent instance into attributes for Event
    class EventMapper < Struct.new(:vevent)
      def to_event_attributes
        {
          uid: vevent.uid,
          title: vevent.summary,
          description: vevent.description,
          url: vevent.url,
          start_time: vevent.start_time,
          end_time: vevent.end_time
        }
      end
    end

    # Converts a VVenue instance into a Venue
    class VenueMapper < Struct.new(:vvenue, :fallback)
      def to_venue_attributes
        attributes = from_vvenue&.attributes || from_fallback&.attributes || {}
        attributes.delete_if { |key| %w[id created_at updated_at].include?(key) }
      end

      private

      def from_vvenue
        return unless vvenue
        Venue.new(
          title: vvenue.name,
          street_address: vvenue.address,
          locality: vvenue.city,
          region: vvenue.region,
          postal_code: vvenue.postalcode,
          country: vvenue.country,
          latitude: vvenue.latitude,
          longitude: vvenue.longitude,
          &:geocode!
        )
      end

      def from_fallback
        return if fallback.blank?
        Venue.new(
          title: "Location:",
          address: fallback,
          &:geocode!
        )
      end
    end
  end
end
