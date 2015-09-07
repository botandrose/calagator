module Calagator
  class Event < ActiveRecord::Base
    class Browse < Struct.new(:order, :start_date, :end_date, :start_time, :end_time)
      def initialize(attributes={})
        members.each do |key|
          send "#{key}=", attributes[key]
        end
      end

      def events
        @events ||= sort.filter_by_date.filter_by_time.scope
      end

      def errors
        @errors ||= []
      end

      def default?
        values.all?(&:blank?)
      end

      protected

      def scope
        @scope ||= Event.non_duplicates.includes(:venue, :tags)
      end

      def sort
        @scope = scope.ordered_by_ui_field(order)
        self
      end

      def filter_by_date
        @scope = if start_date || end_date
          scope.within_dates(start_date, end_date)
        else
          scope.future
        end
        self
      end

      def filter_by_time
        @scope = after_time if start_time
        @scope = before_time if end_time
        self
      end
      
      private

      def before_time
        scope.select { |event| event.end_time.hour <= end_time.hour }
      end

      def after_time
        scope.select { |event| event.start_time.hour >= start_time.hour }
      end
    end

    Browse = Class.new(Browse) do
      def start_date
        format_date super
      end
      
      def start_date= value
        return super default_start_date unless value.present
        super Date.parse(value)
      rescue NoMethodError, ArgumentError, TypeError
        errors << "Can't filter by an invalid start date."
        super default_start_date
      end

      private def default_start_date
        Time.zone.today 
      end

      def end_date
        format_date super
      end

      def end_date= value
        return super default_end_date unless value.present
        super Date.parse(value)
      rescue NoMethodError, ArgumentError, TypeError
        errors << "Can't filter by an invalid end date."
        super default_end_date
      end

      private def default_end_date
        3.months.from_now
      end

      def start_time
        format_time(super) if super
      end

      def start_time= value
        super parse_time(value)
      end

      def end_time
        format_time(super) if super
      end

      def end_time= value
        super parse_time(value)
      end

      private

      def format_date value
        value.strftime('%Y-%m-%d')
      end

      def format_time value
        value.strftime('%I:%M %p')
      end

      def parse_time value
        Time.zone.parse(value)
      rescue NoMethodError, ArgumentError, TypeError
        nil
      end
    end
  end
end
