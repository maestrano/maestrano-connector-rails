require 'spec_helper'

describe Maestrano::Connector::Rails::Organization do

  # Attributes
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:tenant) }
  it { should validate_uniqueness_of(:uid) }
  it { should serialize(:synchronized_entities) }

  # Indexes
  it { should have_db_index([:uid, :tenant]) }

  # Associations
  it { should have_many(:user_organization_rels) }
  it { should have_many(:users) }
  it { should have_many(:id_maps).dependent(:destroy) }
  it { should have_many(:synchronizations).dependent(:destroy) }

  describe 'creation' do
    subject { Maestrano::Connector::Rails::Organization.new }

    it 'initializes the synchronized entities' do
      entities_list = Maestrano::Connector::Rails::External.entities_list
      expect(subject.synchronized_entities).to include(entities_list.first.to_sym)
      expect(subject.synchronized_entities).to include(entities_list.last.to_sym)
    end

    it 'does not allow organizations with the same oauth UID' do
      organization1 = create(:organization, oauth_provider: 'myapp', oauth_uid: 'ABC')
      organization2 = build(:organization, oauth_provider: 'myapp', oauth_uid: 'ABC')
      expect(organization2).not_to be_valid
    end

    it 'allows several organizations without oauth UID' do
      organization1 = create(:organization, oauth_provider: 'myapp', oauth_uid: nil)
      organization2 = build(:organization, oauth_provider: 'myapp', oauth_uid: nil)
      expect(organization2).to be_valid
    end
  end

  describe "instance methods" do
    subject { create(:organization) }

    describe 'add_member' do

      context "when user is not from the same tenant" do
        let(:user) { create(:user, tenant: 'zzz') }

        it "does nothing" do
          expect{
            subject.add_member(user)
          }.to change{Maestrano::Connector::Rails::UserOrganizationRel.count}.by(0)
        end
      end

      context "when user is from the same tenant" do
        let(:user) { create(:user) }

        context "when user is already in the organization" do
          before { create(:user_organization_rel, user: user, organization: subject) }

          it "does nothing" do
          expect{
            subject.add_member(user)
          }.to change{Maestrano::Connector::Rails::UserOrganizationRel.count}.by(0)
          end
        end

        context "when user is not in the organization yet" do
          it "does nothing" do
            expect{
              subject.add_member(user)
            }.to change{Maestrano::Connector::Rails::UserOrganizationRel.count}.by(1)
          end
        end
      end
    end

    describe 'member?' do
      let(:user) { create(:user) }

      context "when user is a member of the organization" do
        before { create(:user_organization_rel, user: user, organization: subject) }

        it { expect(subject.member?(user)).to be(true) }
      end

      context "when user is not a member of the organization" do
        it { expect(subject.member?(user)).to be(false) }
      end
    end

    describe 'remove_member' do
      let(:user) { create(:user) }

      context "when user is a member of the organization" do
        before { create(:user_organization_rel, user: user, organization: subject) }

        it "deletes the user_organization_rel" do
          expect{
            subject.remove_member(user)
          }.to change{Maestrano::Connector::Rails::UserOrganizationRel.count}.by(-1)
        end
      end
      context "when user is not a member of the organization" do
        it "does nothing" do
          expect{
            subject.remove_member(user)
          }.to change{Maestrano::Connector::Rails::UserOrganizationRel.count}.by(0)
        end
      end
    end

    describe 'from_omniauth' do
      let(:saml_hash) { {provider: :maestrano, uid: 'cld-1234', info: {org_uid: 'org-abcd', name: 'My Company'}} }
      let(:tenant) { 'mytenant' }

      let(:subject) { Maestrano::Connector::Rails::Organization.find_or_create_for_maestrano(saml_hash, tenant) }

      context 'with a new organization' do
        it 'creates an organization from SAML parameters' do
          expect(subject.name).to eql('My Company')
          expect(subject.org_uid).to eql('org-abcd')
          expect(subject.tenant).to eql(tenant)
        end
      end

      context 'with an existing organization' do
        let!(:organization) { create(:organization, provider: :maestrano, tenant: tenant, uid: 'cld-1234') }

        it 'find the organization from SAML parameters' do
          expect(subject).to eql(organization)
        end
      end
    end

    describe 'last_three_synchronizations_failed?' do
      it 'returns true when last three syncs are failed' do
        3.times do
          subject.synchronizations.create(status: 'ERROR')
        end
        expect(subject.last_three_synchronizations_failed?).to be true
      end

      it 'returns false when on of the last three sync is success' do
        subject.synchronizations.create(status: 'SUCCESS')
        2.times do
          subject.synchronizations.create(status: 'ERROR')
        end

        expect(subject.last_three_synchronizations_failed?).to be false
      end

      it 'returns false when no sync' do
        expect(subject.last_three_synchronizations_failed?).to be false
      end

      it 'returns false when less than three sync' do
        2.times do
          subject.synchronizations.create(status: 'ERROR')
        end

        expect(subject.last_three_synchronizations_failed?).to be false
      end
    end

    describe 'last_successful_synchronization' do
      let!(:running_sync) { create(:synchronization, organization: subject, status: 'RUNNING') }
      let!(:failed_sync) { create(:synchronization, organization: subject, status: 'ERROR') }
      let!(:success_sync) { create(:synchronization, organization: subject, status: 'SUCCESS', updated_at: 1.minute.ago) }
      let!(:success_sync2) { create(:synchronization, organization: subject, status: 'SUCCESS', updated_at: 3.hours.ago) }
      let!(:partial) { create(:synchronization, organization: subject, status: 'SUCCESS', partial: true) }

      it { expect(subject.last_successful_synchronization).to eql(success_sync) }
    end

    describe 'last_synchronization_date' do
      let(:date) { 2.days.ago }

      context 'with date_filtering_limit' do
        before {
          subject.date_filtering_limit = date
        }

        it { expect(subject.last_synchronization_date).to eql(date) }
      end

      context 'with sync' do
        let!(:success_sync) { create(:synchronization, organization: subject, status: 'SUCCESS') }

        it { expect(subject.last_synchronization_date.to_date).to eql(success_sync.updated_at.to_date) }
      end

      context 'with both' do
        let!(:success_sync) { create(:synchronization, organization: subject, status: 'SUCCESS') }
        before {
          subject.date_filtering_limit = date
        }

        it 'returns the sync date' do
          expect(subject.last_synchronization_date.to_date).to eql(success_sync.updated_at.to_date)
        end
      end

      context 'with none' do
        it { expect(subject.last_synchronization_date).to eql(nil) }
      end
    end

    describe '#reset_synchronized_entities' do
      let(:hash1) { {can_push_to_connec: true, can_push_to_external: true} }
      let(:hash2) { {can_push_to_connec: false, can_push_to_external: false} }
      let(:organization) { create(:organization, synchronized_entities: {entity1: true, entity2: true, tomatoes: false}) }
      subject { organization.reset_synchronized_entities }

      it 'keeps only the known entities' do
        subject
        expect(organization.synchronized_entities).to eql(entity1: hash1, entity2: hash1)
      end

      it 'adds missing entities' do
        organization.update_attributes(synchronized_entities: {entity1: true, tomatoes: false})

        subject
        expect(organization.synchronized_entities).to eql(entity1: hash1, entity2: hash2)
      end

      context 'with metadata from mnohub' do
        before {
          organization.push_disabled = true
          organization.pull_disabled = true
        }


        it 'takes into account the metadata' do
          subject
          expect(organization.synchronized_entities).to eql(entity1: hash2, entity2: hash2)
        end
      end
    end
  end
end
