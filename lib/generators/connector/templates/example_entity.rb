# TODO
# This file is provided as an example and should be removed
# One such file needs to be created for each syncable entity,
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

# class ExampleEntityMapper
#   extend HashMapper

#   def self.set_organization(organization_id)
#     @@organization_id = organization_id
#   end

#   map from('/title'), to('/Salutation')
#   map from('/first_name'), to('/FirstName')
#   map from('address_work/billing2/city'), to('OtherCity')
# end