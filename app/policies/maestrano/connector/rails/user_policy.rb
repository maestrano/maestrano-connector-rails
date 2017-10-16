# frozen_string_literal: true

class Maestrano::Connector::Rails::UserPolicy < Maestrano::Connector::Rails::ApplicationPolicy
  def create?
    true
  end

  class Scope < Scope
  end
end
