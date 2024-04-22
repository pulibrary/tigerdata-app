# frozen_string_literal: true
module TigerData
  class MetadataError < StandardError
  end

  class MissingMetadata 
        def self.missing_metadata(schema_version:, fields:)
            # include current expected metadata schema version number, as well as what metadata is missing
            @fields = fields
            byebug
            raise TigerData::MetadataError, "My error msg" if true
        end
    end
end
