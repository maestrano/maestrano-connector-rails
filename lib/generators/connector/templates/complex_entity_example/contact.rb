# TODO
# This file is provided as an example and should be removed
# See README for explanation
# class SubComplexEntities::Contact < Maestrano::Connector::Rails::SubComplexEntityBase

#   def external?
#     true
#   end

#   def entity_name
#     'contact'
#   end

#   def mapper_classes
#     [SubComplexEntities::ContactMapper]
#   end

#   def map_to(name, entity, organization)
#     case name
#     when 'person'
#       SubComplexEntities::ContactMapper.denormalize(entity)
#     else
#       raise "Impossible mapping from #{self.entity_name} to #{name}"
#     end
#   end
# end