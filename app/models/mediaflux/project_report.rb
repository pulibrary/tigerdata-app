# frozen_string_literal: true
module Mediaflux
  class ProjectReport < Request
    # Specifies the Mediaflux service to use when pulling a report of projects in mediaflux
    # @return [String]
    def self.service
      "tigerdata.project.export.generate"
    end

    def csv_data
      response_xml.xpath("/response/reply/result/result").text
    end
  end
end
