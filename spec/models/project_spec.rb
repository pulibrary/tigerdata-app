# frozen_string_literal: true
require "rails_helper"

RSpec.describe Project, type: :model, stub_mediaflux: true do
  describe "#sponsored_projects" do
    let(:sponsor) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 222", data_sponsor: sponsor.uid)
      FactoryBot.create(:project, title: "project 333", data_sponsor: sponsor.uid)
    end

    it "returns projects for the sponsor" do
      sponsored_projects = described_class.sponsored_projects("hc1234")
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(sponsored_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end
  describe "#managed_projects" do
    let(:manager) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 222", data_manager: manager.uid)
      FactoryBot.create(:project, title: "project 333", data_manager: manager.uid)
    end

    it "returns projects for the manager" do
      managed_projects = described_class.managed_projects("hc1234")
      expect(managed_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(managed_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end

  describe "#data_users" do
    let(:data_user) { FactoryBot.create(:user, uid: "hc1234") }
    before do
      FactoryBot.create(:project, title: "project 111", data_user_read_only: [data_user.uid])
      FactoryBot.create(:project, title: "project 222", data_user_read_only: [data_user.uid])
      FactoryBot.create(:project, title: "project 333", data_user_read_only: [data_user.uid])
    end

    it "returns projects for the data users" do
      data_user_projects = described_class.data_user_projects("hc1234")
      expect(data_user_projects.find { |project| project.metadata[:title] == "project 111" }).not_to be nil
      expect(data_user_projects.find { |project| project.metadata[:title] == "project 222" }).not_to be nil
      expect(data_user_projects.find { |project| project.metadata[:title] == "project 444" }).to be nil
    end
  end

  describe "#pending_projects" do
    before do
      FactoryBot.create(:project, title: "project 111", mediaflux_id: 1111)
      FactoryBot.create(:project, title: "project 222", mediaflux_id: 2222)
      FactoryBot.create(:project, title: "project 333")
    end

    it "returns projects that are not in mediaflux" do
      pending_projects = described_class.pending_projects
      expect(pending_projects.find { |project| project.metadata[:title] == "project 111" and project.mediaflux_id == 1111 }).to be nil
      expect(pending_projects.find { |project| project.metadata[:title] == "project 222" and project.mediaflux_id == 2222 }).to be nil
      expect(pending_projects.find { |project| project.metadata[:title] == "project 333" and project.mediaflux_id.nil? }).not_to be nil
    end
  end

  describe "#approved_projects" do
    before do
      FactoryBot.create(:project, title: "project 111", mediaflux_id: 1111)
      FactoryBot.create(:project, title: "project 222", mediaflux_id: 2222)
      FactoryBot.create(:project, title: "project 333")
    end

    it "returns projects that are not in mediaflux" do
      approved_projects = described_class.approved_projects
      expect(approved_projects.find { |project| project.metadata[:title] == "project 111" and project.mediaflux_id == 1111 }).not_to be nil
      expect(approved_projects.find { |project| project.metadata[:title] == "project 222" and project.mediaflux_id == 2222 }).not_to be nil
      expect(approved_projects.find { |project| project.metadata[:title] == "project 333" and project.mediaflux_id.nil? }).to be nil
    end
  end

  describe "#provenance_events" do
    let(:project) { FactoryBot.create(:project) }
    let(:submission_event) { FactoryBot.create(:submission_event, project: project) }
    it "has many provenance events" do
      expect(project.provenance_events).to eq [submission_event]
    end
    it "only creates one provenance event" do
      project.provenance_events.create(event_type: ProvenanceEvent::SUBMISSION_EVENT_TYPE, event_person: project.metadata["created_by"],
                                       event_details: "Requested by #{project.metadata_json['data_sponsor']}")
      expect(project.provenance_events.count).to eq 1
    end
  end

  describe "#file_list" do
    let(:manager) { FactoryBot.create(:user, uid: "hc1234") }
    let(:project) do
      project = FactoryBot.create(:project, title: "project 111", data_manager: manager.uid)
      project.mediaflux_id = "123"
      project
    end

    before do
      # define query to fetch file list
      # (returns iterator 456)
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query\" session=\"test-session-token\">\n    <args>\n      "\
        "<where>asset in static collection or subcollection of 123</where>\n      <action>get-values</action>\n      "\
        "<xpath ename=\"name\">name</xpath>\n      <xpath ename=\"path\">path</xpath>\n      <xpath ename=\"total-size\">content/@total-size</xpath>\n      "\
        "<xpath ename=\"mtime\">mtime</xpath>\n      <xpath ename=\"collection\">@collection</xpath>\n      <as>iterator</as>\n    </args>\n  </service>\n</request>\n",
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Connection" => "keep-alive",
                "Content-Type" => "text/xml; charset=utf-8",
                "Keep-Alive" => "30",
                "User-Agent" => "Ruby"
              })
        .to_return(status: 200, body: "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\r\n<response><reply><result><iterator>456</iterator></result></reply></response>", headers: {})

      # fetch file list using iterator 456
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
        .with(body: "<?xml version=\"1.0\"?>\n<request>\n  <service name=\"asset.query.iterate\" session=\"test-session-token\">\n    "\
        "<args>\n      <id>456</id>\n      <size>10</size>\n    </args>\n  </service>\n</request>\n",
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Connection" => "keep-alive",
                "Content-Type" => "text/xml; charset=utf-8",
                "Keep-Alive" => "30",
                "User-Agent" => "Ruby"
              })
        .to_return(status: 200, body: fixture_file("files/iterator_response_get_values.xml"), headers: {})

      # destroy the iterator
      stub_request(:post, "http://mediaflux.example.com:8888/__mflux_svc__")
        .with(body: /asset.query.iterator.destroy/,
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Connection" => "keep-alive",
                "Content-Type" => "text/xml; charset=utf-8",
                "Keep-Alive" => "30",
                "User-Agent" => "Ruby"
              })
        .to_return(status: 200, body: "", headers: {})
    end

    xit "fetches the file list" do
      file_list = project.file_list(session_id: "test-session-token", size: 10)
      expect(file_list[:files].count).to eq 8
      expect(file_list[:files][0].name).to eq "file1.txt"
      expect(file_list[:files][0].path).to eq "/td-demo-001/localbig-ns/localbig/file1.txt"
      expect(file_list[:files][0].size).to be 141
      expect(file_list[:files][0].collection).to be false
      expect(file_list[:files][0].last_modified).to eq "2024-02-12T11:43:25-05:00"
    end
  end
end
