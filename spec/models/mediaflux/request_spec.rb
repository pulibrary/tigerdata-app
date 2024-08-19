# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Request, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new }
  let(:mediaflux_url) { "http://mflux-ci.lib.princeton.edu/__mflux_svc__" }
  let(:mediaflux_response) { "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n" }

  describe "#resolve" do
    it "raises an error" do
      expect { request.resolve }.to raise_error(NotImplementedError, "Mediaflux::Request is an abstract class, please override Mediaflux::Request.service")
    end

    context "with a Class derived from Request" do
      subject(:custom_request) { CustomRequest.new(file: file) }

      before do
        class CustomRequest < described_class
          def self.service
            "custom.service"
          end
        end
      end

      after do
        Object.send(:remove_const, :CustomRequest)
      end

      context "when the request transmits a file over the HTTP" do
        let(:file) { fixture_file_upload("test.txt") }

        describe "#resolve" do
          before do
            custom_request.resolve
          end

          it "transmits the POST request as a file upload request" do
            expect(a_request(:post, mediaflux_url).with { |req| req.headers["Content-Type"] == "multipart/form-data" }).to have_been_made
            expect(custom_request.response_body).to include(mediaflux_response)
          end
        end
      end
    end
  end
end
