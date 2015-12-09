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
# end

# class ExampleEntityMapper < Maestrano::Connector::Rails::GenericMapper
#   extend HashMapper

#   map from('/title'), to('/Salutation')
#   map from('/first_name'), to('/FirstName')
#   map from('address_work/billing2/city'), to('City')
# end