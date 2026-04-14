# frozen_string_literal: true
require "rails_helper"

RSpec.describe PULCache do
  describe "#check!" do
    let(:subject) { described_class.new }

    before do
      if ENV["CI"].present?
        # In CI, we want to test that the cache is working at all, so we use the memory store.
        puts "Running in CI environment, using memory store for cache."
        puts "Current cache store: #{Rails.cache.class.name}"
        puts Rails.env.test?.to_s
        puts ENV["TEST"].present?
        config = Rails.application.config
        config.consider_all_requests_local = true
        config.action_mailer.perform_caching = false
        config.cache_store = :memory_store
        puts "Current cache store: #{Rails.cache.class.name}"
      end
    end

    after do
      if ENV["CI"].present?
        # Reset the cache store to the default for other tests.
        config = Rails.application.config
        config.consider_all_requests_local = true
        config.action_mailer.perform_caching = true
        config.cache_store = :null_store
      end
    end

    it "writes and reads the same value" do
      expect { subject.check! }.not_to raise_error
    end

    it "raises an exception if the values are different" do
      allow(Rails.cache).to receive(:read).and_return((1.hour.from_now).to_fs(:rfc2822))
      expect { subject.check! }.to raise_error(PULCacheException, /different values/)
    end
  end
end
