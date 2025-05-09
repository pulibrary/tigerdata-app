# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectXmlPresenter, type: :model, connect_to_mediaflux: false do
  let(:project) { FactoryBot.create :project }
  subject(:presenter) { described_class.new(project) }

  it "can be instantiated" do
    expect(presenter).to be_instance_of(described_class)
  end

  context "rails XML payload" do
    it 'has an xml payload' do
      
    end
    
  end
  
end
