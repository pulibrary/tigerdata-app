# frozen_string_literal: true

FactoryBot.define do
  factory :provenance_event, class: "ProvenanceEvent" do
    event_person { FFaker::InternetSE.unique.login_user_name }
    factory :submission_event do
      event_type { ProvenanceEvent::SUBMISSION_EVENT_TYPE }
      event_details { "Requested by #{FFaker::Name.name}" }
    end
    factory :approval_event do
      event_type { ProvenanceEvent::APPROVAL_EVENT_TYPE }
      event_details { "The project was approved by #{FFaker::Name.name}" }
      event_note do
        {
          NoteBy: FFaker::Name.name.to_s,
          NoteDateTime: Time.current.in_time_zone("America/New_York").iso8601,
          EventType: "Other",
          Message: "Filler Message"
        }
      end
    end
    factory :status_update_event do
      event_type { ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE }
      event_details { "The Status was updated from pending to approved" }
    end
  end
end
