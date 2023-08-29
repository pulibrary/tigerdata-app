# frozen_string_literal: true

FactoryBot.define do
  factory :organization, class: "Organization" do
    id { rand(100) }
    name { FFaker::Company.name }
    path { "td-meta-1" }
    title { FFaker::Movie.title }
    store { "db" }
    initialize_with do
      org = new(id, name, path, title)
      org.store = store
      org
    end
  end
end
