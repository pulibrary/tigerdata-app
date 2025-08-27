# frozen_string_literal: true

require "rails_helper"
require "open-uri"

RSpec.describe "The Skeletor Metadata", connect_to_mediaflux: true, metadata: true do
  it "recognizes a test" do
    x = "metadata"
    expect(x).to eq "metadata"
  end
end
