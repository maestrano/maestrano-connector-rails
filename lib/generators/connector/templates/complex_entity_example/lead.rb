# TODO
# This file is provided as an example and should be removed
# See README for explanation
# class Entities::SubEntities::Lead < Maestrano::Connector::Rails::SubEntityBase

#   def self.external?
#     true
#   end

#   def self.entity_name
#     'lead'
#   end

#   def self.mapper_classes
#     {
#       'person' => Entities::SubEntities::LeadMapper
#     }
#   end

#   def self.object_name_from_connec_entity_hash(entity)
#     "#{entity['first_name']} #{entity['last_name']}"
#   end

#   def self.object_name_from_external_entity_hash(entity)
#     "#{entity['FirstName']} #{entity['LastName']}"
#   end
# end