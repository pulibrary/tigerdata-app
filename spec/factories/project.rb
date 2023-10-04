# frozen_string_literal: true

FactoryBot.define do
  factory :project, class: "Project" do
    metadata do
      {
        data_sponsor: "xx123",
        data_manager: "yy456",
        departments: ["RDSS", "PRDS"],
        directory: "big-data",
        title: FFaker::Movie.title,
        description: "a random description"
      }
    end
    created_by_user_id { FactoryBot.create(:user).id }
  end
end
