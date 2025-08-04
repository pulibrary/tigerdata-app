# frozen_string_literal: true
module TigerData
  class MetadataError < StandardError
  end

  class MissingMetadata
    def self.missing_metadata(schema_version:, errors:)
      error_messages = errors.full_messages.join(", ")
      # include current expected metadata schema version number, as well as what metadata is missing
      raise TigerData::MetadataError, "Project creation failed with metadata schema version #{schema_version} due to the missing fields: #{error_messages}"
    end
  end
end
