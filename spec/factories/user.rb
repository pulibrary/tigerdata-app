FactoryBot.define do
    factory :user do
      sequence(:uid) { "uid#{srand}" }
      sequence(:email) { "email-#{srand}@princeton.edu" }
      provider 'cas'
      password 'foobarfoo'
    end
  end