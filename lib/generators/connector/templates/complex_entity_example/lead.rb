# TODO
# This file is provided as an example and should be removed
# See README for explanation
# class Entities::SubEntities::Lead < Maestrano::Connector::Rails::SubEntityBase

#   def external?
#     true
#   end

#   def entity_name
#     'lead'
#   end

#   def mapper_classes
#     [Entities::SubEntities::LeadMapper]
#   end

#   def map_to(name, entity, organization)
#     case name
#     when 'person'
#       Entities::SubEntities::LeadMapper.denormalize(entity).merge(is_lead: true)
#     else
#       raise "Impossible mapping from #{self.entity_name} to #{name}"
#     end
#   end
# end