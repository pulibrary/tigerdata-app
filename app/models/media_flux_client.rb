# frozen_string_literal: true
require "net/http"
require "nokogiri"

# A very simple client to interface with a MediaFlux server.
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
class MediaFluxClient

  def self.default_instance
    Rails.logger.info "Connecting to MF"
    transport = Rails.configuration.mediaflux["api_transport"]
    host = Rails.configuration.mediaflux["api_host"]
    port = Rails.configuration.mediaflux["api_port"]
    domain = Rails.configuration.mediaflux["api_domain"]
    user = Rails.configuration.mediaflux["api_user"]
    password = Rails.configuration.mediaflux["api_password"]
    MediaFluxClient.new(transport, host, port, domain, user, password)
  end

  def initialize(transport, host, port, domain, user, password)
    @transport = transport
    @host = host
    @port = port
    @domain = domain
    @user = user
    @password = password
    @base_url = "#{transport}://#{host}:#{port}/__mflux_svc__/"
    @xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>'
    connect
  end

  # Fetches MediaFlux's server version information (in XML)
  def version
    xml_request = <<-XML_BODY
      <request>
        <service name="server.version" session="#{@session_id}"/>
      </request>
    XML_BODY
    response_body = http_post(xml_request)

    xml = Nokogiri::XML(response_body)
    version_info = {
      vendor: xml.xpath("/response/reply/result/vendor").text,
      version: xml.xpath("/response/reply/result/version").text
    }
    version_info
  end

  # Terminates the current session
  def logout
    xml_request = <<-XML_BODY
      <request>
        <service name="system.logoff" session="#{@session_id}"/>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    response_body
  end

  # Queries for assets on the given namespace
  def query(aql_where, idx: 1, size: 10)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.query" session="#{@session_id}">
          <args>
            <where>#{aql_where}</where>
            <idx>#{idx}</idx>
            <size>#{size}</size>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    xml = Nokogiri::XML(response_body)
    ids = xml.xpath("/response/reply/result/id").children.map(&:text)
    cursor = xml.xpath("/response/reply/result/cursor")
    # total is only the actual total when the "complete" attribute is true,
    # otherwise it reflects the total fetched so far
    result = {
      ids: ids,
      size: xml.xpath("/response/reply/result/size").text.to_i,
      cursor: {
        count: cursor.xpath("./count").text.to_i,
        from: cursor.xpath("./from").text.to_i,
        to: cursor.xpath("./to").text.to_i,
        prev: cursor.xpath("./prev").text.to_i,
        next: cursor.xpath("./next").text.to_i,
        total: cursor.xpath("./total").text.to_i,
        remaining: cursor.xpath("./remaining").text.to_i
      }
    }
    result
  end

  def query_collection(collection_id, idx: 1, size: 10)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.query" session="#{@session_id}">
          <args>
            <collection>#{collection_id}</collection>
            <idx>#{idx}</idx>
            <size>#{size}</size>
            <action>get-name</action>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    xml = Nokogiri::XML(response_body)
    ids = xml.xpath("/response/reply/result/id").children.map(&:text)
    cursor = xml.xpath("/response/reply/result/cursor")
    files = []
    xml.xpath("/response/reply/result").children.each do |node|
      if node.name == "name"
        files << {id: node.xpath("./@id").text, name: node.text }
      else
        # it's the cursor node, ignore it
      end
    end
    # total is only the actual total when the "complete" attribute is true,
    # otherwise it reflects the total fetched so far
    result = {
      ids: ids,
      files: files,
      size: xml.xpath("/response/reply/result/size").text.to_i,
      cursor: {
        count: cursor.xpath("./count").text.to_i,
        from: cursor.xpath("./from").text.to_i,
        to: cursor.xpath("./to").text.to_i,
        prev: cursor.xpath("./prev").text.to_i,
        next: cursor.xpath("./next").text.to_i,
        total: cursor.xpath("./total").text.to_i,
        complete: cursor.xpath("./total/@complete").text == "true",
        remaining: nil
      }
    }

    if cursor.xpath("./total/@remaining").text != ""
      result[:cursor][:remaining] = cursor.xpath("./total/@remaining").text.to_i
    end

    result
  end

  # Fetches metadata for the given asset it
  def get_metadata(id)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.get" session="#{@session_id}">
          <args>
            <id>#{id}</id>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    xml = Nokogiri::XML(response_body)
    asset = xml.xpath("/response/reply/result/asset")
    metadata = {
      id: asset.xpath("./@id").text,
      creator: asset.xpath("./creator/user").text,
      description: asset.xpath("./description").text,
      collection: asset.xpath("./@collection")&.text == "true",
      name: asset.xpath("./name").text,
      path: asset.xpath("./path").text,
      type: asset.xpath("./type").text,
      size: asset.xpath("./content/size").text,
      size_human: asset.xpath("./content/size/@h").text,
      namespace: asset.xpath("./namespace").text,
      namespace_id: (asset.xpath("./namespace/@id").text || "").to_i
    }

    image = asset.xpath("./meta/mf-image")
    if image.count > 0
      metadata[:image_size] = image.xpath("./width").text + " X " + image.xpath("./height").text
    end

    note = asset.xpath("./meta/mf-note")
    if note.count > 0
      metadata[:mf_note] = note.text
    end

    metadata
  end

  def get_content(id)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.get" session="#{@session_id}" data-out-min="1" data-out-max="1">
          <args>
            <id>#{id}</id>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request, true)
    response_body
  end

  def set_note(id, mf_note)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.set" session="#{@session_id}">
          <args>
            <id>#{id}</id>
            <meta>
              <mf-note>
                <note>#{mf_note}</note>
              </mf-note>
            </meta>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    response_body
  end

  # Creates an empty file (no content) with the name provided
  def create(namespace, filename)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.create" session="#{@session_id}" data-out-min="0" data-out-max="0">
          <args>
            <name>#{filename}</name>
            <namespace>#{namespace}</namespace>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    response_body
  end

  # Creates a collection asset inside a namespace
  def create_collection_asset(namespace, name)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.create" session="#{@session_id}" data-out-min="0" data-out-max="0">
          <args>
            <name>#{name}</name>
            <namespace>#{namespace}</namespace>
            <collection contained-asset-index="true" unique-name-index="true">true</collection>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    xml = Nokogiri::XML(response_body)
    id = xml.xpath("//response/reply/result").text.to_i
    id
  end

  def add_new_files_to_collection(collection_id, count, pattern)
    # asset.test.create :base-name "$project-file-" :nb 5 :pid $pid
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.test.create" session="#{@session_id}" data-out-min="0" data-out-max="0">
          <args>
            <pid>#{collection_id}</pid>
            <nb>#{count}</nb>
            <base-name>#{pattern}</base-name>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    xml = Nokogiri::XML(response_body)
    true
  end

  def namespace_exists?(namespace)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.namespace.exists" session="#{@session_id}" data-out-min="0" data-out-max="0">
          <args>
            <namespace>#{namespace}</namespace>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    xml = Nokogiri::XML(response_body)
    xml.xpath("//response/reply/result").text == "true"
  end

  def namespace_create(namespace)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.namespace.create" session="#{@session_id}" data-out-min="0" data-out-max="0">
          <args>
            <namespace>#{namespace}</namespace>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    response_body
  end

  def namespace_list(parent_namespace)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.namespace.list" session="#{@session_id}" data-out-min="0" data-out-max="0">
          <args>
            <namespace>#{parent_namespace}</namespace>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    xml = Nokogiri::XML(response_body)
    namespaces = []
    xml.xpath("/response/reply/result/namespace/namespace").each.each do |ns|
      id = ns.xpath("@id").text
      name = ns.text
      namespaces << { id: id, name: ns.text }
    end
    namespaces
  end

  def namespace_describe(id)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.namespace.describe" session="#{@session_id}" data-out-min="0" data-out-max="0">
          <args>
            <id>#{id}</id>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    xml = Nokogiri::XML(response_body)
    node = xml.xpath("/response/reply/result/namespace")
    namespace = {
      id: id,
      path: node.xpath("./path").text,
      name: node.xpath("./name").text
    }
    namespace
  end

  def namespace_collection_assets(namespace)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.query" session="#{@session_id}" data-out-min="0" data-out-max="0">
          <args>
            <where>namespace=#{namespace}</where>
            <where>asset is collection</where>
            <action>get-meta</action>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    xml = Nokogiri::XML(response_body)
    collection_assets = []
    xml.xpath("/response/reply/result/asset").each do |node|
      collection_asset = {
        id: node.xpath("./@id").text,
        path: node.xpath("./path").text,
        name: node.xpath("./name").text
      }
      collection_assets << collection_asset
    end
    collection_assets
  end

  # Creates an empty file (no content) with the name provided in the collection indicated
  def create_in_collection(collection, filename)
    xml_request = <<-XML_BODY
      <request>
        <service name="asset.create" session="#{@session_id}" data-out-min="0" data-out-max="0">
          <args>
            <pid>#{collection}</pid>
            <name>#{filename}</name>
          </args>
        </service>
      </request>
    XML_BODY
    response_body = http_post(xml_request)
    response_body
  end

  # Uploads a file to the given namespace
  def upload(namespace, filename_fullpath)
    filename = File.basename(filename_fullpath)
    xml_request = <<-XML_BODY
    <request>
      <service name="asset.create" session="#{@session_id}">
        <args>
          <namespace create="True">#{namespace}</namespace>
          <name>#{filename}</name>
          <meta><mf-name><name>#{filename}</name></mf-name></meta>
        </args>
        <attachment></attachment>
      </service>
    </request>
    XML_BODY
    file_content = File.read(filename_fullpath)
    response_body = http_post(xml_request, true, file_content)
    response_body
  end

  private

    # rubocop:disable Metrics/AbcSize
    def http_post(payload, mflux = false, file_content = nil)
      url = @base_url
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if url.start_with?("https://")
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Post.new(url)

      xml = @xml_declaration + payload
      if mflux == false
        request["Content-Type"] = "text/xml"
        request.body = xml
      else
        # Here be dragons
        # Requests are built different for this content-type
        request["Content-Type"] = "application/mflux"
        mflux_request = if file_content.nil?
                          xml_separator(xml) + xml
                        else
                          xml_separator(xml) + xml + content_separator(file_content) + file_content
                        end
        request.body = mflux_request
      end

      response = http.request(request)
      if response.content_type == "application/mflux"
        metadata_only_header = "\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000y\u0000\u0000\u0000\u0000\u0000\btext/xml"
        if response.body[0..23] == metadata_only_header
          # Response includes only metadata
          response.body[24..]
        else
          # Here be more dragons.
          # Response include metadata + content.
          # Horrible hack to extract the content
          header = response.body[0..23]
          metadata_size = length_from_header(header)
          start_at = metadata_size + 24 + 24 + 2 # metadata_size + header + header + 2
          response.body[start_at..]
        end
      else
        response.body
      end
    end
    # rubocop:enable Metrics/AbcSize

    def xml_separator(xml)
      # 01 00 xx xx xx xx xx xx xx xx 00 00 00 01 yy yy
      file_format = "text/xml"
      part1 = 1.chr + 0.chr + hex_bytes(xml.length)
      part2 = 0.chr + 0.chr + 0.chr + 1.chr + 0.chr + file_format.length.chr
      part1 + part2 + file_format
    end

    def content_separator(content)
      # 01 00 xx xx xx xx xx xx xx xx 00 00 00 01 00 00
      part1 = 1.chr + 0.chr + hex_bytes(content.length)
      part2 = 0.chr + 0.chr + 0.chr + 1.chr + 0.chr + 0.chr
      part1 + part2
    end

    def hex_bytes(number)
      hex_bytes = []
      # Force the string to be 16 characters long so we can guarantee 8 pairs.
      number_hex = number.to_s(16).rjust(16, "0")
      8.times do |i|
        n = i * 2
        hex = number_hex[n..n + 1]
        hex_bytes << hex.to_i(16).chr
      end
      hex_bytes.join
    end

    # header: "\x01\x00\x00\x00\x00\x00\x00\x00\a\xF7\x00\x00\x00\x01\x00\btext/xml"
    # length: 7F7 hex => 2039 dec
    def length_from_header(header)
      hex_str = ""
      data = header[2..9]
      data.each_char do |c|
        hex_str += c.ord.to_s(16).rjust(2, "0")
      end
      hex_str.to_i(16)
    end

    def connect
      xml_request = <<-XML_BODY
        <request>
          <service name="system.logon">
            <args>
              <host>#{@host}</host>
              <domain>#{@domain}</domain>
              <user>#{@user}</user>
              <password>#{@password}</password>
            </args>
          </service>
        </request>
      XML_BODY
      response_body = http_post(xml_request)
      xml = Nokogiri::XML(response_body)

      session_element = xml.xpath("//response/reply/result/session").first
      @session_id = session_element&.text
    end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
