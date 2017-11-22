# frozen_string_literal: true

class Maestrano::Connector::Rails::OrganizationPolicy < Maestrano::Connector::Rails::ApplicationPolicy
  def create?
    true
  end
end
