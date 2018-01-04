require 'spec_helper'

describe Maestrano::Connector::Rails::UserOrganizationRel, type: :model do

  # Attributes

  # Indexes
  it { should have_db_index(:user_id) }
  it { should have_db_index(:organization_id) }

  #Associations
  it { should belong_to(:user) }
  it { should belong_to(:organization) }
end
