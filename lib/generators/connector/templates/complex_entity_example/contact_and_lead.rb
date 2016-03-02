# TODO
# This file is provided as an example and should be removed
# See README for explanation
# class Entities::ContactAndLead < Maestrano::Connector::Rails::ComplexEntity
#   def connec_entities_names
#     %w(person)
#   end

#   def external_entities_names
#     %w(contact lead)
#   end

#   # input :  {
#   #             connec_entity_names[0]: [unmapped_connec_entitiy1, unmapped_connec_entitiy2],
#   #             connec_entity_names[1]: [unmapped_connec_entitiy3, unmapped_connec_entitiy4]
#   #          }
#   # output : {
#   #             connec_entity_names[0]: {
#   #               external_entities_names[0]: [unmapped_connec_entitiy1, unmapped_connec_entitiy2]
#   #             },
#   #             connec_entity_names[1]: {
#   #               external_entities_names[0]: [unmapped_connec_entitiy3],
#   #               external_entities_names[1]: [unmapped_connec_entitiy4]
#   #             }
#   #          }
#   def connec_model_to_external_model(connec_hash_of_entities)
#     people = connec_hash_of_entities['person']
#     modeled_connec_entities = {'person' => { 'lead' => [], 'contact' => [] }}

#     people.each do |person|
#       if person['is_lead']
#         modeled_connec_entities['person']['lead'] << person
#       else
#         modeled_connec_entities['person']['contact'] << person
#       end
#     end
#     return modeled_connec_entities
#   end

#   # input :  {
#   #             external_entities_names[0]: [unmapped_external_entity1, unmapped_external_entity2],
#   #             external_entities_names[1]: [unmapped_external_entity3, unmapped_external_entity4]
#   #          }
#   # output : {
#   #             external_entities_names[0]: {
#   #               connec_entity_names[0]: [unmapped_external_entity1],
#   #               connec_entity_names[1]: [unmapped_external_entity2]
#   #             },
#   #             external_entities_names[1]: {
#   #               connec_entity_names[0]: [unmapped_external_entity3, unmapped_external_entity4]
#   #             }
#   #           }
#   def external_model_to_connec_model(external_hash_of_entities)
#     return {'lead' => {'person' => external_hash_of_entities['lead']}, 'contact' => {'person' => external_hash_of_entities['contact']}}
#   end
# end