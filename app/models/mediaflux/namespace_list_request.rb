# frozen_string_literal: true
module Mediaflux
  # List all of the namespaces that are inside of a given namespace
  # @example
  #   namespace_list = Mediaflux::NamespaceListRequest.new(session_token: session_id, parent_namespace: "/td-test-001/tigerdataNS").namespaces
  #   => [{:id=>"1264", :name=>"Avocado1NS"}, {:id=>"1282", :name=>"Banana1NS"}]
  class NamespaceListRequest < Request
    attr_reader :parent_namespace

    # Constructor
    # @param session_token [String] the API token for the authenticated session, same as session_id
    # @param parent_namespace [String] Parent namespace for the query
    def initialize(session_token:, parent_namespace:)
      super(session_token: session_token)
      @parent_namespace = parent_namespace
    end

    # Specifies the Mediaflux service to use when creating assets
    # @return [String]
    def self.service
      "asset.namespace.list"
    end

    def namespaces
      @namespaces ||= begin
                        xml = response_xml
                        namespaces = []
                        xml.xpath("/response/reply/result/namespace/namespace").each.each do |ns|
                          id = ns.xpath("@id").text
                          namespaces << { id: id, name: ns.text }
                        end
                        namespaces
                      end
    end

    private

      def build_http_request_body(name:)
        super do |xml|
          xml.args do
            xml.namespace parent_namespace
          end
        end
      end
  end
end
