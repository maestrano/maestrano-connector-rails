# TODO
# This file is provided as an example and should be removed
# See README for explanation
# class Entities::SubEntities::Contact < Maestrano::Connector::Rails::SubEntityBase

#   def external?
#     true
#   end

#   def entity_name
#     'contact'
#   end

#   def map_to(name, entity, organization)
#     case name
#     when 'person'
#       Entities::SubEntities::ContactMapper.denormalize(entity)
#     else
#       raise "Impossible mapping from #{self.entity_name} to #{name}"
#     end
#   end
# end