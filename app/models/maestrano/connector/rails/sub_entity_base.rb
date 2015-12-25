module Maestrano::Connector::Rails
  class SubEntityBase < Entity

    def external?
      raise "Not implemented"
    end

    def entity_name
      raise "Not implemented"
    end

    def mapper_classes
      raise "Not implemented"
    end

    def map_to(name, entity, organization)
      raise "Not implemented"
    end

    def external_entity_name
      if self.external?
        self.entity_name
      else
        raise "Forbidden call"
      end
    end

    def connec_entity_name
      if self.external?
        raise "Forbidden call"
      else
        self.entity_name
      end
    end
  end
end