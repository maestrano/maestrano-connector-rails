require 'spec_helper'

describe Maestrano::Connector::Rails::Synchronization do

  # Attributes
  it { should validate_presence_of(:status) }

  # Indexes
  it { should have_db_index(:organization_id) }

  #Associations
  it { should belong_to(:organization) }
end