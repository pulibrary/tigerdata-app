# frozen_string_literal: true
module Mediaflux
  module Http
    # Get metadata about an asset in mediaflux
    # @example
    #   metadata_request = Mediaflux::Http::AssetMetadataRequest.new(
    #   session_token: current_user.mediaflux_session, id: mediaflux_id).metadata
    class AssetMetadataRequest < Request
      attr_reader :id

      # Constructor
      # @param session_token [String] the API token for the authenticated session
      # @param id [Integer] Id of the Asset to return the metadata for
      def initialize(session_token:, id:)
        super(session_token: session_token)
        @id = id
      end

      # Specifies the Mediaflux service to use when getting asset metadata
      # @return [String]
      def self.service
        "asset.get"
      end

      # parse the returned XML into a hash about the asset that can be utilized
      def metadata
        xml = response_xml
        asset = xml.xpath("/response/reply/result/asset")
        metadata = parse(asset)

        if metadata[:collection]
          metadata[:total_file_count] = asset.xpath("./collection/accumulator/value/non-collections").text
          metadata[:size] = asset.xpath("./collection/accumulator/value/total/@h").text
          metadata[:quota_allocation] = asset.xpath("./collection/quota/allocation/@h").text
          metadata[:ctime] = asset.xpath("./ctime")

        end

        parse_image(asset.xpath("./meta/mf-image"), metadata) # this does not do anything because mf-image is not a part of the meta xpath

        parse_note(asset.xpath("./meta/mf-note"), metadata) # this does not do anything because mf-note is not a part of the meta xpath

        metadata
      end

      private

        def build_http_request_body(name:)
          super do |xml|
            xml.args do
              xml.id id
            end
          end
        end

        def parse_note(note, metadata)
          if note.count > 0
            metadata[:mf_note] = note.text
          end
        end

        def parse_image(image, metadata)
          if image.count > 0
            metadata[:image_size] = image.xpath("./width").text + " X " + image.xpath("./height").text
          end
        end

        # Update this to match full 0.6.1 schema
        def parse(asset)
          {
            id: asset.xpath("./@id").text,
            name: asset.xpath("./name").text,
            creator: asset.xpath("./creator/user").text,
            description: asset.xpath("./description").text,
            collection: asset.xpath("./@collection")&.text == "true",
            path: asset.xpath("./path").text,
            type: asset.xpath("./type").text,
            namespace: asset.xpath("./namespace").text,
            accumulators: asset.xpath("./collection/accumulator/value") # list of accumulator values in xml format. Can parse further through xpath
          }.merge(parse_project(asset.xpath("//tigerdata:project", "tigerdata" => "tigerdata").first))
        end

        def parse_project(project)
          return {} if project.blank?
          {
            created_by: project.xpath("./CreatedBy").text,
            created_on: project.xpath("./CreatedOn").text,
            description: project.xpath("./Description").text,
            data_sponsor: project.xpath("./DataSponsor").text,
            data_manager: project.xpath("./DataManager").text,
            departments: project.xpath("./Department").children.map(&:text),
            project_directory: project.xpath("./ProjectDirectory").text,
            project_id: project.xpath("./ProjectID").text,
            ro_users: project.xpath("./DataUser[@ReadOnly]").map(&:text),
            rw_users: project.xpath("./DataUser[not(@ReadOnly)]").map(&:text),
            submission: parse_submission(project),
            title: project.xpath("./Title").text
          }
        end

        def parse_submission(project)
          submission = project.xpath("./Submission")
          {
            requested_by: submission.xpath("./RequestedBy").text,
            requested_on: submission.xpath("./RequestDateTime").text,
            approved_by: submission.xpath("./ApprovedBy").text,
            approved_on: submission.xpath("./ApprovalDateTime").text
          }
        end
    end
  end
end
