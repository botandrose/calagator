# frozen_string_literal: true

module Calagator
  class Event < Calagator::ApplicationRecord
    class Browse
      include ActiveModel::Model

      attr_accessor :order, :start_date, :end_date, :tags

      def tags
        @tags ||= []
      end

      def events
        @events ||= sort.filter_by_date.filter_by_tags.scope
      end

      def errors
        @errors ||= {}
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
        @scope = if end_date.present?
          scope.within_dates(start_date, end_date)
        else
          scope.on_or_after_date(start_date)
        end
        self
      end

      def filter_by_tags
        if tags.any?
          @scope = scope.tagged_with(tags, any: true)
        end
        self
      end
    end
  end
end
