module Maestrano
  module Api
    class BaseResource < JSONAPI::Resource
      abstract
      include Pundit::Resource

      API_SQL_OPERATOR_MAPPING = {
        gt: '>',
        gte: '>=',
        lt: '<',
        lte: '<=',
        ne: '<>',
        like: 'LIKE'
      }.freeze

      def self.all_filters
        # Skipping if there is no tables as calling columns_hash in attribute_type is causing issue
        return unless tables_exists?
        _attributes.keys.each do |attribute|
          type = attribute_type(attribute)
          if type == :boolean
            # https://github.com/cerebris/jsonapi-resources/issues/852
            # make sure filter applied on boolean works
            filter(attribute, verify: :verify_boolean_filter)
          else
            filter(attribute)
          end
        end
        generate_composite_filters
      end

      def self.generate_composite_filters
        _allowed_filters.keys.each do |key|
          # iterating through all the api operator and adding them as custom filter
          # name.gt, name.like etc...
          next unless _model_class
          field = "#{_model_class.table_name}.#{key}"

          API_SQL_OPERATOR_MAPPING.each do |api_operator, sql_operator|
            filter "#{key}.#{api_operator}",
                   apply: ->(records, value, _options) { records.where("#{field} #{sql_operator} ?", value[0]) }
          end
          filter "#{key}.none",
                 apply: ->(records, value, _options) { records.where("#{field} IS NULL") }
          filter "#{key}.not",
                 apply: ->(records, value, _options) { value[0] ? records.where("#{field} <> ?", value[0]) : records.where("#{field} IS NOT NULL") }
          filter "#{key}.nin",
                 apply: ->(records, value, _options) { records.where("#{field} NOT IN (?)", value) }
          filter "#{key}.in",
                 apply: ->(records, value, _options) { records.where("#{field} IN (?)", value) }
        end
      end

      def self.attribute_type(attribute)
        _model_class.columns_hash[attribute.to_s]&.type || :string
      rescue
        :string
      end

      # If the code is loaded before table are created (during a schema:load for example) this will return false
      def self.tables_exists?
        @tables_exists = ActiveRecord::Base.connection.table_exists?('users') if @tables_exists.nil?
        @tables_exists
      end
    end
  end
end
