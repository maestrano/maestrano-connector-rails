module Connector
  module Generators
    class ComplexEntityGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def copy_example_files
        copy_file 'complex_entity_example/contact_and_lead.rb', 'app/models/entities/example_contact_and_lead.rb'

        copy_file 'complex_entity_example/contact.rb', 'app/models/entities/sub_entities/example_contact.rb'
        copy_file 'complex_entity_example/contact_mapper.rb', 'app/models/entities/sub_entities/example_contact_mapper.rb'

        copy_file 'complex_entity_example/lead.rb', 'app/models/entities/sub_entities/example_lead.rb'
        copy_file 'complex_entity_example/lead_mapper.rb', 'app/models/entities/sub_entities/example_lead_mapper.rb'

        copy_file 'complex_entity_example/person.rb', 'app/models/entities/sub_entities/example_person.rb'
      end
    end
  end
end
