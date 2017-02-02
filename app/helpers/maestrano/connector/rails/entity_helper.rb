module Maestrano::Connector::Rails
  module EntityHelper
    def self.snake_name(entity)
      class_name = entity.class.name.underscore.split('/').last
      if entity.is_a?(Maestrano::Connector::Rails::SubEntityBase)
        name = ''
        Entities.constants&.each do |c|
          klass = Entities.const_get(c)
          next unless klass.respond_to?(:formatted_external_entities_names)
          if klass.formatted_external_entities_names.values.include?(class_name.camelize) ||
             klass.formatted_connec_entities_names.values.include?(class_name.camelize)
            name = c
            break
          end
        end
        name.to_s.underscore.to_sym
      else
        class_name.to_sym
      end
    end
  end
end
