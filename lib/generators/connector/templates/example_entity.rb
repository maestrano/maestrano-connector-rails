# frozen_string_literal: true
# TODO
# This file is provided as an example and should be removed
# One such file needs to be created for each synchronizable entity,
# with its associated mapper

# class Entities::ExampleEntity < Maestrano::Connector::Rails::Entity
#   def self.connec_entity_name
#     'ExampleEntity'
#   end

#   def self.external_entity_name
#     'Contact'
#   end

#   def self.mapper_class
#     ExampleEntityMapper
#   end

# This method is optional. It is needed only if a mandatory field
# is missing in Connec! and has to be pushed with a default value on creation.
# Refer to the FAQ section for more details.

#   def self.creation_mapper_class
#     CreationExampleEntityMapper
#   end

#   def self.object_name_from_connec_entity_hash(entity)
#     "#{entity['first_name']} #{entity['last_name']}"
#   end

#   def self.object_name_from_external_entity_hash(entity)
#     "#{entity['FirstName']} #{entity['LastName']}"
#   end

# end

# class CreationExampleEntityMapper < ExampleEntityMapper
#
#   after_normalize do |input, output|
#     output[:missing_connec_field] = "Default Value"
#   end
# end

# class ExampleEntityMapper
#   extend HashMapper

#   map from('title'), to('Salutation')
#   map from('first_name'), to('FirstName')
#   map from('address_work/billing2/city'), to('City')
# end
