# frozen_string_literal: true
require "rails_helper"

RSpec.describe MediafluxChannel, type: :channel, connect_to_mediaflux: true do
  subject(:channel) { described_class.new(*args) }

  let(:connection) { double(ActionCable::Connection) }
  let(:identifier) { "test-channel" }
  let(:args) do
    [
      connection,
      identifier
    ]
  end
  let(:superuser) { FactoryBot.create(:superuser, mediaflux_session: SystemUser.mediaflux_session) }

  before do
    superuser
    allow(connection).to receive(:identifiers).and_return([])
    allow(channel).to receive(:transmit)
    allow(channel).to receive(:update_state).and_call_original
    allow(described_class).to receive(:new).and_return(channel)
  end

  describe "#subscribed" do
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
