# frozen_string_literal: true
require "rails_helper"

RSpec.describe MediafluxChannel, type: :channel do
  subject(:channel) { described_class.new(*args) }

  let(:connection) { double(ActionCable::Connection) }
  let(:identifier) { "test-channel" }
  let(:args) do
    [
      connection,
      identifier
    ]
  end
  let(:superuser) { FactoryBot.create(:superuser) }

  before do
    superuser
    allow(connection).to receive(:identifiers).and_return([])
    allow(channel).to receive(:transmit)
    allow(channel).to receive(:update_state).and_call_original
    allow(described_class).to receive(:new).and_return(channel)
  end

  describe "#subscribed" do
  #TODO: refactor the stub_mediaflux to connect to the real mediaflux
    #     2 Tests: 32, 57
    before do
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").to_return(status: 200, body: "", headers: {})
    end

    it "updates the state based upon the Mediaflux version request" do
      channel.subscribed

      expect(channel).to have_received(:update_state)
      expect(channel).to have_received(:transmit).with(state: true)
    end
  end

  describe "#unsubscribed" do
    it "updates the state to 'false'" do
      channel.unsubscribed

      expect(channel).to have_received(:transmit).with(state: false)
    end
  end

  describe "#update_state" do
    context "when the Mediaflux version cannot be retrieved" do
      let(:version_request) { instance_double(Mediaflux::VersionRequest) }
      before do
        stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__").to_return(status: 200, body: "", headers: {})
        allow(version_request).to receive(:version).and_return(nil)
        allow(Mediaflux::VersionRequest).to receive(:new).and_return(version_request)
      end

      it "returns a value of 'false'" do
        channel.update_state

        expect(channel).to have_received(:transmit).with(state: false)
      end
    end
  end
end
