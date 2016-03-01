# TODO
# This file is provided as an example and should be removed
# One such file needs to be created for each synchronizable entity,
# with its associated mapper

# class Entities::ExampleEntity < Maestrano::Connector::Rails::Entity
#   def connec_entity_name
#     'ExampleEntity'
#   end

#   def external_entity_name
#     'Contact'
#   end

#   def mapper_class
#     ExampleEntityMapper
#   end

#   def object_name_from_connec_entity_hash(entity)
#     "#{entity['first_name']} #{entity['last_name']}"
#   end

#   def object_name_from_external_entity_hash(entity)
#     "#{entity['FirstName']} #{entity['LastName']}"
#   end

# end

# class ExampleEntityMapper
#   extend HashMapper

#   map from('/title'), to('/Salutation')
#   map from('/first_name'), to('/FirstName')
#   map from('address_work/billing2/city'), to('City')
# end