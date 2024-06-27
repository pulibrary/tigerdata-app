# frozen_string_literal: true
module Mediaflux
  class Time
    # Converts the givin time snippet into local princeton time while accounting for potential time zone of the asset.
    #
    # @param xml_snip [:nokigiri], response_xml from a mediaflux request
    # @return [String] returns a iso8601 Princeton time value.
    def convert(xml_snip:)
      xml = xml_snip
      time = xml.text.to_time
      gmt = xml.xpath("./@gmt-offset").text.to_f

      if gmt.zero?
        return time.in_time_zone("America/New_York").iso8601
      elsif gmt.positive?
        time -= gmt.hours
      else
        time += gmt.hours
      end

      princeton_time = time.in_time_zone("America/New_York").iso8601
      princeton_time
    end

    # Transform iso8601 dates to MediaFlux expected format
    # @example
    #   MediafluxTime.format_date_for_mediaflux("2024-02-26T10:33:11-05:00") => "22-FEB-2024 13:57:19"
    def self.format_date_for_mediaflux(iso8601_date)
      return if iso8601_date.nil?
      Object::Time.zone.parse(iso8601_date).strftime("%e-%b-%Y %H:%M:%S").upcase
    end
  end
end
