# frozen_string_literal: true
module Mediaflux
  class Connection
    attr_reader :https, :session

    def initialize
      @https = Net::HTTP.new(Rails.configuration.mediaflux["api_host"], Rails.configuration.mediaflux["api_port"])
      # @https.use_ssl = true

      @session = login
    end

    protected

      def login
        response = build_request("system.logon") do |xml|
          xml.args do
            xml.domain Rails.configuration.mediaflux["api_domain"]
            xml.user Rails.configuration.mediaflux["api_user"]
            xml.password Rails.configuration.mediaflux["api_password"]
          end
        end
        Rails.logger.debug response.body
        doc = Nokogiri::XML.parse(response.body)
        Rails.logger.debug doc
        doc.xpath("response/reply/result/session").text
      end

      def build_request(name, form_file = nil)
        args = { name: name }
        args[:session] = session unless session.nil?
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.request do
            xml.service(**args) do
              yield xml if block_given?
            end
          end
        end
        send_request(builder, form_file)
      end

      def send_request(builder, form_file)
        request = Net::HTTP::Post.new("/__mflux_svc__")
        if form_file.nil?
          request["Content-Type"] = "text/xml; charset=utf-8"
          request.body = builder.to_xml
        else
          request["Content-Type"] = "multipart/form-data"
          request.set_form({ "request" => builder.to_xml,
                             "nb-data-attachments" => "1",
                             "file_0" => form_file },
                        "multipart/form-data",
                        "charset" => "UTF-8")
        end
        https.request(request)
      end
  end
end
