require 'rails_helper'

RSpec.describe Request, type: :model do
  let(:request) { described_class.create(request_type: 'new_project_request', request_title: "Request for Example Project", project_title: "Example Project") }
  
  describe '#request_type' do
    subject(:request_type) { request.request_type }
  end

  describe '#request_title' do
    subject(:request_title) { request.request_title }
  end

  describe '#project_title' do
    subject(:project_title) { request.project_title }
  end
end