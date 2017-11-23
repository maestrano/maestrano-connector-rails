# frozen_string_literal: true

class Maestrano::Connector::Rails::IdMapPolicy < Maestrano::Connector::Rails::ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.includes(:organization).where('organizations.tenant': user)
    end
  end
end
