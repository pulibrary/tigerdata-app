# frozen_string_literal: true

FactoryBot.define do
  factory :project, class: "Project" do
    transient do
      data_sponsor { FactoryBot.create(:user).uid }
      data_manager { FactoryBot.create(:user).uid }
      title { FFaker::Movie.title }
    end
    metadata do
      {
        data_sponsor: data_sponsor,
        data_manager: data_manager,
        departments: ["RDSS", "PRDS"],
        directory: "big-data",
        title: title,
        description: "a random description",
        created_by: FactoryBot.create(:user).uid
      }
    end
  end
end
