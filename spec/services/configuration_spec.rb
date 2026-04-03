# frozen_string_literal: true

require "rails_helper"

RSpec.describe :tigerdata_configuration, type: :model do
  describe "project_file_display_limit" do
    it "loads into the RailsConfiguration" do
      expect(Rails.configuration.project_file_display_limit).to eq(50)
    end
  end
end
