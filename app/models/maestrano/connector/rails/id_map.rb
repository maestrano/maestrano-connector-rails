module Maestrano::Connector::Rails
  class IdMap < ActiveRecord::Base
    before_save: :normalize_entity_names

    private
      def normalize_entity_names
        self.connec_entity = self.connec_entity.downcase.singularize
        self.external_entity = self.external_entity.downcase.singularize
      end
  end
end