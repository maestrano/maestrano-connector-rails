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

#   def object_name_from_connec_entity_hash(entity)
#     "#{entity['first_name']} #{entity['last_name']}"
#   end

#   def object_name_from_external_entity_hash(entity)
#     "#{entity['FirstName']} #{entity['LastName']}"
#   end
# end