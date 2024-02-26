# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::HttpConnection, type: :model do
  subject(:connection) { described_class.new }

  describe "#instance" do
    it "returns the same one" do
      a = Mediaflux::Http::HttpConnection.instance
      b = Mediaflux::Http::HttpConnection.instance
      expect(a == b).to be_truthy
    end

    it "works with threads" do
      @initial_connection = Mediaflux::Http::HttpConnection.instance
      threads = []
      21.times do
        threads << Thread.new { expect(@initial_connection == Mediaflux::Http::HttpConnection.instance).to be_truthy }
      end
      threads.each(&:join)
    end
  end
end
