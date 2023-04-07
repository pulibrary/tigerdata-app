# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::Request, type: :model do
  subject(:request) { described_class.new }
  let(:mediflux_url) { "http://test.mediaflux.com:443/__mflux_svc__" }

  describe "#resolve" do
    it "raises an error" do
      expect { request.resolve }.to raise_error(NotImplementedError, "Mediaflux::Http::Request is an abstract class, please override Mediaflux::Http::Request.service")
    end

    context "with a Class derived from Request" do
      subject(:custom_request) { CustomRequest.new(file: file) }

      before do
        class CustomRequest < described_class
          def self.service
            "custom.service"
          end
        end

        stub_request(:post, mediflux_url).to_return(
          status: 200
        )
      end

      after do
        Object.send(:remove_const, :CustomRequest)
      end

      context "when the request transmits a file over the HTTP" do
        let(:file) { fixture_file_upload("test.txt") }

        describe "#resolve" do
          before do
            WebMock.enable!

            custom_request.resolve
          end

          after do
            WebMock.disable!
          end

          it "transmits the POST request as a file upload request" do
            expect(a_request(:post, mediflux_url).with { |req| req.headers["Content-Type"] == "multipart/form-data" }).to have_been_made
          end
        end
      end
    end
  end
end
