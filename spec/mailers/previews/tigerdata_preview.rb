# frozen_string_literal: true
# Preview all emails at http://localhost:3000/rails/mailers/tigerdata
require "factory_bot"
FactoryBot.find_definitions

class TigerdataPreview < ActionMailer::Preview
  def welcome_email
    project = Project.last || FactoryBot.create(:project)
    approver = User.find(id = 12)
    TigerdataMailer.with(project_id: project.id, approver:).project_creation
  end
end
