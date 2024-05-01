# frozen_string_literal: true
require "rails_helper"

RSpec.describe TestProjectGenerator, connect_to_mediaflux: true do
  let(:subject) { described_class.new(user:, number: 1, project_prefix: 'test-project') }
  let(:user) { FactoryBot.create :user }
  let(:user2) { FactoryBot.create :user }
  let(:user3) { FactoryBot.create :user }

  before do
    # make sure 3 users exist
    user2
    user3
  end

  describe "#generate" do

    it "creates test data" do
      subject.generate
      expect(project).to be_persisted
      # expect(user).to have_received(:mediaflux_session)
      # expect(test_collection_create).to have_received(:id)
      # expect(test_namespace_describe).to have_received(:exists?)
      # expect(test_namespace_create).to have_received(:error?)
      # expect(parent_metadata_request).to have_received(:error?)
      # expect(test_accum_size_create).to have_received(:resolve)
      # expect(test_accum_count_create).to have_received(:resolve)
    end
  end
end
