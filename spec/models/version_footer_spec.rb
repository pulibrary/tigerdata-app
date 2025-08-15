# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/ExampleLength
RSpec.describe VersionFooter do
  describe "info" do
    context "with stale information" do
      before do
        described_class.revision_file = Pathname.new(fixture_path).join("REVISION").to_s
        described_class.revisions_logfile = Pathname.new(fixture_path).join("revisions_stale.log").to_s
        described_class.reset!
      end

      it "detects stale information" do
        info = described_class.info
        expect(info[:stale]).to be true
        expect(info[:sha]).to eq "2222ae5c4ad9aaa0faad5208f1bf8108bd5934bf"
        expect(info[:branch]).to eq "version-2"
        expect(info[:version]).to eq "02 December 2021"
        expect(info[:tagged_release]).to be false
      end
    end

    context "with current information" do
      before do
        described_class.revision_file = Pathname.new(fixture_path).join("REVISION").to_s
        described_class.revisions_logfile = Pathname.new(fixture_path).join("revisions_current.log").to_s
        described_class.reset!
      end
      it "detects current information" do
        info = described_class.info
        expect(info[:stale]).to be false
        expect(info[:sha]).to eq "7a3b1d7c0f77db526963568ece3e0bb5a6399ce4"
        expect(info[:branch]).to eq "v0.8.0"
        expect(info[:version]).to eq "10 December 2021"
        expect(info[:tagged_release]).to be true
      end
    end
  end

  describe ".stale?" do
    context "with nil revision information" do
      before do
        described_class.revision_file = nil
        described_class.reset!
      end

      it "assumes that a version is stale" do
        expect(described_class.stale?).to be true
      end
    end

    context "with stale information" do
      before do
        described_class.revision_file = Pathname.new(fixture_path).join("REVISION").to_s
        described_class.revisions_logfile = Pathname.new(fixture_path).join("revisions_stale.log").to_s
        described_class.reset!
      end

      it "confirms that a version is stale" do
        expect(described_class.stale?).to be true
      end
    end
  end

  describe ".version" do
    context "with a nil revisions logfile" do
      before do
        described_class.revisions_logfile = nil
        described_class.reset!
      end

      it "indicates that the application is not in a deployed environment" do
        expect(described_class.version).to eq "Not in deployed environment"
      end
    end
  end

  describe ".git_sha" do
    context "with a nil revisions logfile" do
      let(:git_sha) do
        `git rev-parse HEAD`.chomp
      end

      before do
        described_class.revisions_logfile = nil
        described_class.reset!
      end

      it "parses the current git SHA" do
        expect(described_class.git_sha).to eq(git_sha)
      end

      context "when outside of the development and test environments" do
        let(:env) { ActiveSupport::EnvironmentInquirer.new("other") }

        before do
          allow(Rails).to receive(:env).and_return(env)
        end

        it "indicates that the application is not in a deployed environment" do
          expect(described_class.git_sha).to eq "Unknown SHA"
        end

        after do
          allow(Rails).to receive(:env).and_call_original
        end
      end
    end
  end

  describe ".branch" do
    context "with a nil revisions logfile" do
      let(:branch) do
        `git rev-parse --abbrev-ref HEAD`.chomp
      end

      before do
        described_class.revisions_logfile = nil
        described_class.reset!
      end

      it "parses the current git branch" do
        expect(described_class.branch).to eq(branch)
      end

      context "when outside of the development and test environments" do
        let(:env) { ActiveSupport::EnvironmentInquirer.new("other") }

        before do
          allow(Rails).to receive(:env).and_return(env)
        end

        it "indicates that the application is not in a deployed environment" do
          expect(described_class.branch).to eq("Unknown branch")
        end

        after do
          allow(Rails).to receive(:env).and_call_original
        end
      end
    end
  end

  context "with rollback information" do
    before do
      described_class.revision_file = Pathname.new(fixture_path).join("REVISION").to_s
      described_class.revisions_logfile = Pathname.new(fixture_path).join("revisions_rollback.log").to_s
      described_class.reset!
    end
    it "detects current information" do
      info = described_class.info
      expect(info[:stale]).to be false
      expect(info[:sha]).to eq "7a3b1d7c0f77db526963568ece3e0bb5a6399ce4"
      expect(info[:branch]).to eq "v0.8.0"
      expect(info[:version]).to eq "10 December 2021"
      expect(info[:tagged_release]).to be true
    end
  end

  context "with an exception" do
    before do
      described_class.revision_file = Pathname.new(fixture_path).join("REVISION").to_s
      described_class.revisions_logfile = Pathname.new(fixture_path).join("revisions_rollback.log").to_s
      described_class.reset!
      allow(described_class).to receive(:log_line).and_raise("Error!!!")
    end
    it "detects current information" do
      info = described_class.info
      expect(info[:error]).to eq("Error retrieving version information: Error!!!")
    end
  end
end
# rubocop enable RSpec/ExampleLength
