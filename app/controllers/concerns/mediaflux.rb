module Mediaflux

  def fake_login(username, password)
    nil
  end

  def login(config)
    response = build_request(nil, "system.logon") do |xml|
      xml.args do
        xml.domain 'TODO: Domain'
        xml.user config[:mf_username]
        xml.password config[:mf_password]
      end
    end

    doc = Nokogiri::XML.parse(response.body)
    doc.xpath("response/reply/result/session").text
  end

  def logoff(https)
    build_request(nil, "system.logoff")
  end

  private

  def get_https()
    https = Net::HTTP.new(config[:mf_host], config[:mf_port])
    https.use_ssl = true
    return https
  end

  def build_request(session, name, form_file=nil)
    https = get_https
    args = { name: name }
    args[:session] = session unless session.nil?
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.request do
        xml.service(**args) do
          yield xml if block_given?
        end
      end
    end

    request = Net::HTTP::Post.new("__mflux_svc__")
    if form_file.nil?
      request["Content-Type"] = "text/xml; charset=utf-8"
      request.body = builder.to_xml
    else
      request["Content-Type"] = 'multipart/form-data'
      request.set_form({ "request" => builder.to_xml, 
                    "nb-data-attachments" => "1", 
                    "file_0" => form_file},
                    "multipart/form-data",
                    "charset" => "UTF-8")
    end  
    https.request(request)
  end

end