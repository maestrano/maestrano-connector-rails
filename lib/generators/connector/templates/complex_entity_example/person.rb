# TODO
# This file is provided as an example and should be removed
# See README for explanation
# class Entities::SubEntities::Person < Maestrano::Connector::Rails::SubEntityBase
#   def self.external?
#     false
#   end

#   def self.entity_name
#     'person'
#   end

#   def self.mapper_classes
#     {
#       'lead' => Entities::SubEntities::LeadMapper,
#       'contact' => Entities::SubEntities::ContactMapper,
#     }
#   end

#   def self.object_name_from_connec_entity_hash(entity)
#     "#{entity['first_name']} #{entity['last_name']}"
#   end

#   def self.object_name_from_external_entity_hash(entity)
#     "#{entity['FirstName']} #{entity['LastName']}"
#   end
# end