# frozen_string_literal: true
require "rails_helper"

RSpec.describe PULCache do
  describe "#check!" do
    let(:subject) { described_class.new }

    before do
      if ENV["CI"].present?
        # In CI, we want to test that the cache is working at all, so we use the memory store.
        config = Rails.application.config
        config.cache_store = :memory_store
      end
    end

    after do
      if ENV["CI"].present?
        # Reset the cache store to the default for other tests.
        config = Rails.application.config
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
