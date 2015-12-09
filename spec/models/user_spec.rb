require 'spec_helper'

describe Maestrano::Connector::Rails::User do

  # Attributes
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:tenant) }

  # Indexes
  it { should have_db_index([:uid, :tenant]) }

  #Associations
  it { should have_many(:user_organization_rels) }
  it { should have_many(:organizations) }
end