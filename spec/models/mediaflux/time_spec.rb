# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mediaflux::Time do
    let(:project) { FactoryBot.build :project_with_doi }
    let(:current_user) { FactoryBot.create(:user, uid: "jh1234") }
    let(:docker_response) { "Etc/UTC" }
    let(:ansible_response) { "America/Chicago" }
    subject(:instance) { described_class.new }

    describe "#convert", connect_to_mediaflux: true do
      it "converts mediaflux time objects to utc before converting to america/new_york" do
        project = FactoryBot.create(:project_with_doi)
        ProjectMediaflux.create!(project: project, user: current_user)
        metadata = Mediaflux::AssetMetadataRequest.new(
          session_token: current_user.mediaflux_session,
          id: project.mediaflux_id
          ).metadata


        xml_snip = metadata[:ctime]
        initial_tz = xml_snip.xpath("./@tz").text

        final_tz = instance.convert(xml_snip:)
<<<<<<< HEAD
        expect(["-04:00", "-05:00"].any? { |tz| final_tz.include?(tz) }).to be_truthy #America/New_York changes based on daylights savings time
=======
        expect(final_tz.include?("-04:00") || final_tz.include?("-05:00")).to be true #America/New_York changes based on daylights savings time
>>>>>>> 267e2dc (Fixed test logic)
      end
    end
    describe "date formatting" do
      let(:project) { FactoryBot.build :project_with_doi }

      context "for MediaFlux" do
        # Mediaflux date format is like " 9-FEB-2024 14:53:23"
        let(:date_regexp) { /\d-[A-Z]{3}-\d{4} \d{2}:\d{2}:\d{2}/ }
        it "looks like 9-FEB-2024 14:53:23" do
          created_on =  project.metadata_model.created_on.strip
          formatted = described_class.format_date_for_mediaflux(created_on)
          expect(formatted.match?(date_regexp)).to eq true
        end
      end
    end
  end
