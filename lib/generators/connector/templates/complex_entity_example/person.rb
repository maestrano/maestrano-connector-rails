# TODO
# This file is provided as an example and should be removed
# See README for explanation
# class Enities::SubEntities::Person < Maestrano::Connector::Rails::SubEntityBase
#   def external?
#     false
#   end

#   def entity_name
#     'person'
#   end

#   def mapper_classes
#     [Enities::SubEntities::ContactMapper, SubComplexEntities::LeadMapper]
#   end

#   def map_to(name, entity, organization)
#     case name
#     when 'lead'
#       Enities::SubEntities::LeadMapper.normalize(entity)
#     when 'contact'
#       Enities::SubEntities::ContactMapper.normalize(entity)
#     else
#       raise "Impossible mapping from #{self.entity_name} to #{name}"
#     end
#   end
# end