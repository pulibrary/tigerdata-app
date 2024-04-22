# frozen_string_literal: true
module TigerData
  class MetadataError < StandardError
  end

  def missing_metadata(schema_version:, metadata:)
    # include current expected metadata schema version number, as well as what metadata is missing
    raise TigerData::MetadataError, "My error msg" unless true
  end
end
