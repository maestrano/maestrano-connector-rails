# frozen_string_literal: true

# Abstract base class for all policies
# @abstract
# @!attribute [r] user
#   @return [User] the current user
# @!attribute [r] record
#   @return [Object] some kind of model object, whose authorization you want to check
class Maestrano::Connector::Rails::ApplicationPolicy
  attr_reader :user, :record

  # Returns a new instance of {BasePolicy}
  # @param [User] user the current user
  # @param [Object] record some kind of model object, whose authorization you want to check
  # @return [ApplicationPolicy]
  def initialize(user, record)
    # Closed system: must be logged in to do anything
    raise Pundit::NotAuthorizedError, 'must be logged in' unless user
    @user = user
    @record = record
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :tenant, :scope

    def initialize(tenant, scope)
      @tenant = tenant
      @scope = scope
    end

    def resolve
      scope_to_tenant
    end

    def scope_to_tenant
      scope.where(tenant: tenant)
    end
  end
end
