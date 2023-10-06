# frozen_string_literal: true
# Preview all emails at http://localhost:3000/rails/mailers/tigerdata
require "factory_bot"
FactoryBot.find_definitions

class TigerdataPreview < ActionMailer::Preview
  def welcome_email
    project = Project.last || FactoryBot.create(:project)
    TigerdataMailer.with(project: project).project_creation
  end
end
