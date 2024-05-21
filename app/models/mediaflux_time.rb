# frozen_string_literal: true
class MediafluxTime
  def convert(xml_snip:)
    # takes an xml snip of a nokigiri based time object from a mediaflux response and returns a Princeton time value
    # xml_snip: (required) The xml path to a time object from mediaflux

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
