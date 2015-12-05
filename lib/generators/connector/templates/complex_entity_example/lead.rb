# TODO
# This file is provided as an example and should be removed
# See README for explanation
# class SubComplexEntities::Lead < Maestrano::Connector::Rails::SubComplexEntityBase

#   def external?
#     true
#   end

#   def entity_name
#     'lead'
#   end

#   def mapper_classes
#     [SubComplexEntities::LeadMapper]
#   end

#   def map_to(name, entity)
#     case name
#     when 'person'
#       SubComplexEntities::LeadMapper.denormalize(entity).merge(is_lead: true)
#     else
#       raise "Impossible mapping from #{self.entity_name} to #{name}"
#     end
#   end
# end