# frozen_string_literal: true
require "rails_helper"

RSpec.describe Affiliation, type: :model do
  describe "#load_from_file" do
    it "reads the departments from the file" do
      expect(Affiliation.count).to eq 0
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      expect(Affiliation.count).to eq 5
      expect(Affiliation.where(code: "55555").first.name).to eq("AST-Astrophysical Sciences")
      expect(Affiliation.where(code: "66666").first.name).to eq("HPC-High Performance Computing")
      expect(Affiliation.where(code: "77777").first.name).to eq("RDSS-Research Data and Scholarship Services")
      expect(Affiliation.where(code: "88888").first.name).to eq("PRDS-Princeton Research Data Service")
      expect(Affiliation.where(code: "99999").first.name).to eq("PPPL-Princeton Plasma Physics Laboratory")
    end

    it "only loads the departments once" do
      expect(Affiliation.count).to eq 0
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      expect(Affiliation.count).to eq 5
      Affiliation.load_from_file(Rails.root.join("spec", "fixtures", "departments.csv"))
      expect(Affiliation.count).to eq 5
    end
  end

  describe "find_fuzzy_by_name" do
    before do
      Affiliation.create(name: "abc123 and other", code: "1")
      Affiliation.create(name: "abc123", code: "2")
    end

    it "finds the exact match first" do
      expect(Affiliation.find_fuzzy_by_name("abc123").code).to eq("2")
    end
    it "orders the fuzzy match by code" do
      expect(Affiliation.find_fuzzy_by_name("abc12").code).to eq("1")
    end
  end
end
