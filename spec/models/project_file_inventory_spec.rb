# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectFileInventory, type: :model do
  describe "#generate" do
    let(:project) { test_project_from_path("/princeton/tigerdata/RDSS/testing-project") }

    it "writes files from the project and its nested collections to a CSV" do
      Tempfile.create(["project-file-inventory", ".csv"]) do |file|
        described_class.new(project:, session_id: SystemUser.mediaflux_session, filename: file.path).generate

        rows = CSV.read(file.path)
        expect(rows.count).to eq(21)
        expect(rows.first).to eq(["ID", " PATH", " NAME", " COLLECTION?", " LAST_MODIFIED", " SIZE"])
        expect(rows[1][1]).to eq(" /princeton/tigerdata/RDSS/testing-project")
        expect(rows[1][2]).to eq(" developer0")
        expect(rows[1][3]).to eq(" false")
        expect(rows[1][5]).to eq(" 10")
        expect(rows[20][1]).to eq(" /princeton/tigerdata/RDSS/testing-project/developer")
        expect(rows[20][2]).to eq(" developer4")
        expect(rows[20][3]).to eq(" false")
        expect(rows[20][5]).to eq(" 10")
      end
    end
  end
end
