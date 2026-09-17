# frozen_string_literal: true
require "rails_helper"

RSpec.describe DataSecurityLevelPresenter do
  describe "#to_s" do
    it "returns Level 0 - Public for level 0" do
      expect(described_class.new(0).to_s).to eq("Level 0 - Public")
    end

    it "returns Level 1 - Internal for level 1" do
      expect(described_class.new(1).to_s).to eq("Level 1 - Internal")
    end

    it "returns Level 2 - Confidential for level 2" do
      expect(described_class.new(2).to_s).to eq("Level 2 - Confidential")
    end

    it "returns Level 3 - Restricted for level 3" do
      expect(described_class.new(3).to_s).to eq("Level 3 - Restricted")
    end

    it "returns Emdash for an unknown level" do
      expect(described_class.new(4).to_s).to eq("<strong class=\"px-0\">&mdash;</strong>".html_safe)
      expect(described_class.new(nil).to_s).to eq("<strong class=\"px-0\">&mdash;</strong>".html_safe)
    end
  end

  describe "#level_name" do
    it "aliases #to_s" do
      expect(described_class.new(1).level_name).to eq("Level 1 - Internal")
    end
  end

  describe ".select_options" do
    it "returns an array of options with disabled levels" do
      expected_options = [
        { value: 0, label: "Level 0 - Public" },
        { value: 1, label: "Level 1 - Internal" },
        { value: 2, label: "Level 2 - Confidential (not yet available in TigerData)", disabled: true },
        { value: 3, label: "Level 3 - Restricted (not yet available in TigerData)", disabled: true }
      ]
      expect(described_class.select_options).to eq(expected_options)
    end
  end
end
