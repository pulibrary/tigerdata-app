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

  context "EOF error" do
    let(:mediaflux_logon) { Mediaflux::LogonRequest.new }

    it "captures and retries EOF errors" do
      
      error_count = 0
      allow(mediaflux_logon).to receive(:resolve).and_wrap_original do |original_method, *args|
        if error_count == 0
          # Force an error the first time to make sure the retry is invoked in the code
          error_count = 1
          raise EOFError, "error"
        else
          original_method.call(*args)
        end
      end

      expect(SystemUser.mediaflux_session).not_to be_nil
    end
  end

end
