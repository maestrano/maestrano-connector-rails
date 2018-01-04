require 'spec_helper'

describe Maestrano::Connector::Rails::IdMap, type: :model do

  # Indexes
  it { should have_db_index([:connec_id, :connec_entity, :organization_id]) }
  it { should have_db_index([:external_id, :external_entity, :organization_id]) }
  it { should have_db_index([:organization_id]) }

  #Associations
  it { should belong_to(:organization) }
end
