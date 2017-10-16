# frozen_string_literal: true

class Maestrano::Connector::Rails::SynchronizationPolicy < Maestrano::Connector::Rails::ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
