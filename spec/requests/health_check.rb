# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Health Check", type: :request do
  describe "GET /health" do
    it "has a health check for Mediaflux" do
      get "/health"
      expect(response).to be_successful
      expect(response.body).to include("MediafluxStatus")
    end
  end
end
