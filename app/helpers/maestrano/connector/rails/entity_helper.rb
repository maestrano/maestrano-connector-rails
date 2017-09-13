module Maestrano::Connector::Rails
  module EntityHelper
    def self.snake_name(entity)
      class_name = entity.class.name.underscore.split('/').last
      if entity.is_a?(Maestrano::Connector::Rails::SubEntityBase)
        name = ''
        Entities.constants&.each do |c|
          klass = Entities.const_get(c)
          next unless klass.respond_to?(:formatted_external_entities_names)

          external_class_names = klass.formatted_external_entities_names.values
          break name = c if camel_case_format(external_class_names).include?(class_name.camelize)

          connec_class_names = klass.formatted_connec_entities_names.values
          break name = c if camel_case_format(connec_class_names).include?(class_name.camelize)
        end
        name.to_s.underscore.to_sym
      else
        class_name.to_sym
      end
    end

    def self.camel_case_format(array_of_class_names)
      array_of_class_names.map { |name| name.titleize.delete(' ') }
    end
  end
end
