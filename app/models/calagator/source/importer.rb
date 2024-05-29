# frozen_string_literal: true

module Calagator
  class Source < Calagator::ApplicationRecord
    class Importer < Struct.new(:source, :events)
      def self.build(params)
        source = Source.find_or_create_by(params)
        new(source)
      end

      def import
        return unless source.valid?

        self.events = source.create_events!

        events.present?.tap do |present|
          source.destroy unless present
        end
      rescue Source::Parser::NotFound
        add_error "No events found at remote site. Is the event identifier in the URL correct?"
      rescue Source::Parser::HttpAuthenticationRequiredError
        add_error "Couldn't import events, remote site requires authentication."
      rescue OpenURI::HTTPError
        add_error "Couldn't download events, remote site may be experiencing connectivity problems."
      rescue Errno::EHOSTUNREACH
        add_error "Couldn't connect to remote site."
      rescue SocketError
        add_error "Couldn't find IP address for remote site. Is the URL correct?"
      rescue => e
        add_error "Unknown error: #{e}"
      end

      def failure_message
        if events.nil?
          "Unable to import: #{source.errors.full_messages.to_sentence}"
        else
          "Unable to find any upcoming events to import from this source"
        end
      end

      private

      def add_error(message)
        source.errors.add :base, message
        nil
      end
    end
  end
end
