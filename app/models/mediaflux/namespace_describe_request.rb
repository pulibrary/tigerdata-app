# frozen_string_literal: true
module Mediaflux
  # Describes a namespace
  # @example
  #   namespace = Mediaflux::NamespaceDescribeRequest.new(session_token: session_id).metadata
  #   => {:id=>"1", :path=>"/", :name=>"", :description=>"", :store=>"data"}
  # @example
  #   namespace = Mediaflux::NamespaceDescribeRequest.new(session_token: session_id, path: "/td-test-001/tigerdataNS").metadata
  #   => {:id=>"1182", :path=>"/td-test-001/tigerdataNS", :name=>"tigerdataNS", :description=>"TigerData client app root namespace", :store=>"db"}
  class NamespaceDescribeRequest < Request
    attr_reader :path, :id

    # Constructor
    # @param session_token [String] the API token for the authenticated session
    # @param path [String] path of the asset to be described
    # @param id [Integer] TODO: Define what this is and how to use it.
    def initialize(session_token:, path: nil, id: nil)
      super(session_token: session_token)
      @path = path
      @id = id
    end

    # Specifies the Mediaflux service to use
    # @return [String]
    def self.service
      "asset.namespace.describe"
    end

    def metadata
      @metadata ||= begin
                      xml = response_xml
                      node = xml.xpath("/response/reply/result/namespace")
                      {
                        id: node.xpath("@id").text,
                        path: node.xpath("./path").text,
                        name: node.xpath("./name").text,
                        description: node.xpath("./description").text,
                        store: node.xpath("./store").text
                      }
                    end
    end

    def exists?
      metadata[:id].present?
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.id id if id.present?
            xml.namespace path if path.present?
          end
        end
      end
  end
end
