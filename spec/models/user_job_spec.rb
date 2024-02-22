# frozen_string_literal: true
require "rails_helper"

RSpec.describe UserJob, type: :model do
  subject(:user_job) { described_class.new }

  describe "#completed_at" do
    let(:completion_time) { DateTime.now }
    let(:formatted) do
      localized = completion_time.localtime
      localized.strftime("%Y-%m-%dT%H:%M:%S%:z")
    end

    before do
      user_job.completed_at = completion_time
    end

    it "accesses the string-formatted timestamp for the time of job completion" do
      expect(user_job.completed_at).not_to be nil
      expect(user_job.completed_at).to eq(formatted)
    end
  end
end
