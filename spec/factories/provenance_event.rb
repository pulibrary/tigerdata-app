# frozen_string_literal: true

FactoryBot.define do
  factory :provenance_event, class: "ProvenanceEvent" do
    event_person { FFaker::InternetSE.unique.login_user_name }
    factory :submission_event do
      event_type { ProvenanceEvent::SUBMISSION_EVENT_TYPE }
      event_details { "Requested by #{FFaker::Name.name}" }
    end
    factory :status_update_event do
      event_type { ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE }
      event_details { "The Status was updated from pending to approved" }
    end
  end
end
