# frozen_string_literal: true
require "rails_helper"

RSpec.describe PULDatacite do
  let(:subject) { described_class.new }
  let(:fake_datacite) { stub_datacite_doi }
  before do
    @datacite_user = Rails.configuration.datacite.user
  end

  after do
    Rails.configuration.datacite.user = @datacite_user
  end

  describe "#draft_doi" do
    let(:datacite_response) { instance_double Datacite::Response, doi: "10.34770/abc123" }
    before do
      allow(fake_datacite).to receive(:autogenerate_doi).and_return(Success(datacite_response))
    end

    it "returns the test doi" do
      Rails.configuration.datacite.user = nil
      expect(subject.draft_doi).to eq("10.34770/tbd")
      expect(fake_datacite).not_to have_received(:autogenerate_doi)
    end

    context "we have a datacite user" do
      before do
        Rails.configuration.datacite.user = "abc"
      end

      it "calls out to datacite" do
        expect(subject.draft_doi).to eq("10.34770/abc123")
        expect(fake_datacite).to have_received(:autogenerate_doi)
      end

      context "there is an error" do
        let(:faraday_response) { instance_double Faraday::Response, reason_phrase: "Bad response", status: 500 }
        before do
          allow(fake_datacite).to receive(:autogenerate_doi).and_return(Failure(faraday_response))
        end

        it "raises an exception" do
          expect { subject.draft_doi }.to raise_error("Error generating DOI. 500 / Bad response")
          expect(fake_datacite).to have_received(:autogenerate_doi)
        end
      end
    end
  end
end
