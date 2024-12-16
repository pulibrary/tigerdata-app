# frozen_string_literal: true
require "rails_helper"

RSpec.describe SystemUser, type: :model do
  let(:mediaflux_logon) { instance_double Mediaflux::LogonRequest, error?: false, session_token: "111222333" }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Mediaflux::LogonRequest).to receive(:new).and_return(mediaflux_logon)
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe "#mediaflux_session" do
    it "calls out to Mediaflux to login" do
      expect(SystemUser.mediaflux_session).to eq("111222333")
      # calling a second time to text the cache
      expect(SystemUser.mediaflux_session).to eq("111222333")
      expect(mediaflux_logon).to have_received(:session_token).once
    end
  end
end
