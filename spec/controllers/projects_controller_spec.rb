# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectsController do
  let(:project) { FactoryBot.create :project }
  describe "#show" do
    it "renders an error when requesting json" do
      get :show, params: { id: project.id, format: :json }
      expect(response.content_type).to eq("application/json; charset=utf-8")
      expect(response.body).to eq("{\"error\":\"You need to sign in or sign up before continuing.\"}")
    end

    context "a signed in user" do
      let(:user) { FactoryBot.create :user }
      before do
        sign_in user
      end

      it "renders the project metadata as json" do
        get :show, params: { id: project.id, format: :json }
        expect(response.content_type).to eq("application/json; charset=utf-8")
        expect(JSON.parse(response.body)).to eq(project.metadata)
      end

      it "renders the project metadata as xml" do
        get :show, params: { id: project.id, format: :xml }
        expect(response.content_type).to eq("application/xml; charset=utf-8")
        expect(response.body).to eq(
        "<?xml version=\"1.0\"?>\n" \
        "<request xmlns:tigerdata=\"http://tigerdata.princeton.edu\">\n" \
        "  <service name=\"asset.create\">\n" \
        "    <args>\n" \
        "      <name>#{project.directory}</name>\n" \
        "      <namespace>/td-test-001/#{project.directory}-ns</namespace>\n" \
        "      <meta>\n" \
        "        <tigerdata:project>\n" \
        "          <code>#{project.directory}</code>\n" \
        "          <title>#{project.metadata[:title]}</title>\n" \
        "          <description>#{project.metadata[:description]}</description>\n" \
        "          <status>#{project.metadata[:status]}</status>\n" \
        "          <data_sponsor>#{project.metadata[:data_sponsor]}</data_sponsor>\n" \
        "          <data_manager>#{project.metadata[:data_manager]}</data_manager>\n" \
        "          <departments>RDSS</departments>\n" \
        "          <departments>PRDS</departments>\n" \
        "          <created_on>#{project.metadata[:created_on]}</created_on>\n" \
        "          <created_by>#{project.metadata[:created_by]}</created_by>\n" \
        "        </tigerdata:project>\n" \
        "      </meta>\n" \
        "      <collection cascade-contained-asset-index=\"true\" contained-asset-index=\"true\" unique-name-index=\"true\">true</collection>\n" \
        "      <type>application/arc-asset-collection</type>\n" \
        "    </args>\n" \
        "  </service>\n" \
        "</request>\n"
      )
      end
    end
  end
end
