# frozen_string_literal: true
class MediafluxTime
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
end
