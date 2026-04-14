# frozen_string_literal: true
require "rails_helper"

RSpec.describe PULCache do
  describe "#check!" do
    let(:subject) { described_class.new }

    before do
      if ENV["CI"].present?
        memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
        allow(Rails).to receive(:cache).and_return(memory_store)
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
